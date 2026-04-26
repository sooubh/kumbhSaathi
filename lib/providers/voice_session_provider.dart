import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../core/config/ai_config.dart';
import '../core/services/realtime_chat_service.dart';
import '../core/services/text_chat_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'language_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum VoiceState { initial, connecting, listening, speaking, error }

class VoiceSessionState {
  final VoiceState status;
  final String text;
  final String? errorMessage;
  final bool isConnected;
  final bool isFallbackMode;
  final bool isRetrying;

  const VoiceSessionState({
    this.status = VoiceState.initial,
    this.text = '',
    this.errorMessage,
    this.isConnected = false,
    this.isFallbackMode = false,
    this.isRetrying = false,
  });

  VoiceSessionState copyWith({
    VoiceState? status,
    String? text,
    String? errorMessage,
    bool clearError = false,
    bool? isConnected,
    bool? isFallbackMode,
    bool? isRetrying,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      text: text ?? this.text,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isConnected: isConnected ?? this.isConnected,
      isFallbackMode: isFallbackMode ?? this.isFallbackMode,
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class VoiceSessionNotifier extends StateNotifier<VoiceSessionState> {
  final Ref _ref;

  VoiceSessionNotifier(this._ref) : super(const VoiceSessionState());

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RealtimeChatService _realtimeService = RealtimeChatService();
  final TextChatService _textChatService = TextChatService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
    level: Level.warning,
  );

  // Stream subscriptions — all cancelled in _cancelSubscriptions()
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<String>? _textSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<void>? _turnCompleteSub;
  StreamSubscription<void>? _interruptedSub;
  StreamSubscription<List<int>>? _recorderSub;

  // ---------------------------------------------------------------------------
  // KEY FIX — single buffer per turn.
  // All raw PCM chunks from one Gemini turn are concatenated here.
  // On turnComplete the whole buffer is wrapped in ONE WAV header and played
  // with a single AudioPlayer.play() call → zero inter-chunk silence.
  // ---------------------------------------------------------------------------
  final List<int> _turnAudioBuffer = [];

  // Prevents re-entrant playback calls
  bool _isPlaying = false;

  // Prevents state updates after dispose
  bool _disposed = false;

  // Track last input to avoid duplicates
  String _lastFallbackInput = '';
  DateTime? _lastInputTime;

  // ---------------------------------------------------------------------------
  // Audio session — configured ONCE per session, never during recording
  // ---------------------------------------------------------------------------
  Future<void> _configureAudioSession() async {
    try {
      final session = await audio_session.AudioSession.instance;
      await session.configure(
        audio_session.AudioSessionConfiguration(
          avAudioSessionCategory:
              audio_session.AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              audio_session.AVAudioSessionCategoryOptions.defaultToSpeaker |
              audio_session.AVAudioSessionCategoryOptions.allowBluetooth |
              audio_session.AVAudioSessionCategoryOptions.allowBluetoothA2dp,
          // voiceChat keeps mic open while speaker plays (full-duplex)
          avAudioSessionMode: audio_session.AVAudioSessionMode.voiceChat,
          avAudioSessionRouteSharingPolicy:
              audio_session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions:
              audio_session.AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: const audio_session.AndroidAudioAttributes(
            contentType: audio_session.AndroidAudioContentType.speech,
            flags: audio_session.AndroidAudioFlags.none,
            usage: audio_session.AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType:
              audio_session.AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );

      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.voiceCommunication,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
            },
          ),
        ),
      );
    } catch (e) {
      _logger.w('Audio session config failed (non-fatal): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Connect
  // ---------------------------------------------------------------------------
  Future<void> connect() async {
    if (_disposed) return;

    try {
      // Cancel any lingering subscriptions from a previous session
      await _cancelSubscriptions();

      _safeSetState(
        state.copyWith(
          status: VoiceState.connecting,
          text: 'Connecting to Gemini...',
          clearError: true,
        ),
      );

      _turnAudioBuffer.clear();
      _isPlaying = false;

      // --- 1. Audio session (once per connect) ---
      await _configureAudioSession();

      // --- 2. Microphone permission ---
      if (!await _audioRecorder.hasPermission()) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _safeSetState(
            state.copyWith(
              status: VoiceState.error,
              errorMessage:
                  'Microphone permission denied. Allow access in device settings.',
            ),
          );
          return;
        }
      }

      // --- 3. Discover and Initialize Models ---
      await AIConfig.initializeModels();

      // --- 4. Connect WebSocket ---
      final userProfile = _ref.read(currentProfileProvider);
      final location = _ref.read(locationProvider).valueOrNull;
      final language = _ref.read(languageProvider);

      try {
        await _realtimeService.connect(
          userProfile: userProfile,
          location: location,
          appLanguage: language.locale.languageCode,
        );
      } catch (e) {
        final errorMsg = e.toString();
        if (errorMsg.contains('429') || errorMsg.contains('RESOURCE_EXHAUSTED')) {
          _logger.w('⚠️ Live API quota exhausted, using fallback mode.');
          _safeSetState(state.copyWith(
            status: VoiceState.error, 
            errorMessage: 'AI Live Quota exhausted. Switching to stable mode...',
          ));
          await Future.delayed(const Duration(seconds: 2));
        } else {
          _logger.w('Realtime connection failed: $e');
        }
        await _switchToFallbackMode();
        return;
      }

      // --- 4. Wire up all streams ---
      _audioSub = _realtimeService.audioStream.listen(_onAudioChunk);

      _textSub = _realtimeService.textStream.listen((text) {
        final t = text.trim();
        if (t.isNotEmpty) _safeSetState(state.copyWith(text: t));
      });

      _errorSub = _realtimeService.errorStream.listen((msg) {
        _safeSetState(
          state.copyWith(
            status: VoiceState.error,
            isConnected: false,
            errorMessage: msg,
          ),
        );
      });

      _connectionSub = _realtimeService.connectionStream.listen((connected) {
        if (!connected && state.status != VoiceState.error) {
          _safeSetState(
            state.copyWith(
              status: VoiceState.error,
              isConnected: false,
              errorMessage: 'Connection dropped. Tap Retry.',
            ),
          );
        }
      });

      // KEY FIX: On turn complete, flush the entire turn as ONE WAV → no gaps
      _turnCompleteSub =
          _realtimeService.turnCompleteStream.listen((_) => _onTurnComplete());

      // KEY FIX: On interruption, stop playing and clear buffer immediately
      _interruptedSub =
          _realtimeService.interruptedStream.listen((_) => _onInterrupted());

      // --- 5. Start microphone stream (stays running for the whole session) ---
      await _startMicStream();

      _safeSetState(
        state.copyWith(
          status: VoiceState.listening,
          isConnected: true,
          isFallbackMode: false,
          text: 'Listening...',
          clearError: true,
        ),
      );
    } catch (e) {
      _logger.e('connect() failed: $e');
      _safeSetState(
        state.copyWith(
          status: VoiceState.error,
          errorMessage: 'Failed to connect: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Fallback Mode (Text AI + STT + TTS)
  // ---------------------------------------------------------------------------
  Future<void> _switchToFallbackMode() async {
    _safeSetState(state.copyWith(status: VoiceState.connecting, text: 'Entering fallback mode...'));

    try {
      bool available = await _speechToText.initialize(
        onError: (val) {
          _logger.e('STT Error: ${val.errorMsg}');
          // KEY FIX: Don't show error screen for 'no_match' (user didn't say anything)
          if (val.errorMsg == 'error_no_match' || val.errorMsg == 'error_speech_timeout') {
            _logger.d('🔇 No speech detected, staying in listening mode.');
            _returnToListening();
            return;
          }
          
          _safeSetState(state.copyWith(
            status: VoiceState.error,
            errorMessage: 'Mic issue: ${val.errorMsg}',
          ));
        },
        onStatus: (val) {
          _logger.d('STT Status: $val');
        },
      );

      if (!available) {
        throw Exception('Speech Recognition not available on this device.');
      }

      await _flutterTts.setLanguage('en-US'); // Will be updated by detection
      await _flutterTts.setSpeechRate(0.5);

      _safeSetState(
        state.copyWith(
          status: VoiceState.listening,
          isConnected: true,
          isFallbackMode: true,
          text: 'Listening (Live mode unavailable)...',
          clearError: true,
        ),
      );

      _startSttListening();
    } catch (e) {
      _logger.e('Fallback mode initialization failed: $e');
      _safeSetState(
        state.copyWith(
          status: VoiceState.error,
          errorMessage: 'Voice assistant unavailable. Error: $e',
        ),
      );
    }
  }

  void _startSttListening() async {
    if (!state.isFallbackMode || !_speechToText.isAvailable) return;

    final language = _ref.read(languageProvider);

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleFallbackInput(result.recognizedWords);
        } else {
          _safeSetState(state.copyWith(text: result.recognizedWords));
        }
      },
      localeId: language.locale.languageCode,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> _handleFallbackInput(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    // 1. Optimization: Prevent parallel requests if already speaking
    if (state.status == VoiceState.speaking && !state.isRetrying) {
      _logger.d('⏳ Assistant is already speaking/thinking, skipping input.');
      return;
    }

    // 2. Optimization: Avoid duplicate triggers (debounce/duplicate check)
    final now = DateTime.now();
    if (_lastFallbackInput == trimmed && 
        _lastInputTime != null && 
        now.difference(_lastInputTime!).inSeconds < 2) {
      _logger.d('⏩ Skipping duplicate input: $trimmed');
      return;
    }
    _lastFallbackInput = trimmed;
    _lastInputTime = now;

    _safeSetState(state.copyWith(status: VoiceState.speaking, text: 'Thinking...'));

    try {
      final userProfile = _ref.read(currentProfileProvider);
      final location = _ref.read(locationProvider).valueOrNull;
      final language = _ref.read(languageProvider);

      final response = await _textChatService.sendMessage(
        trimmed,
        userProfile: userProfile,
        location: location,
        appLanguage: language.locale.languageCode,
      );

      final cleanText = response.content.replaceAll(RegExp(r'\[[a-z]{2}\]\s*'), '').trim();
      _safeSetState(state.copyWith(text: cleanText, isRetrying: false));

      await _flutterTts.speak(cleanText);
      await _flutterTts.awaitSpeakCompletion(true);
      
      _returnToListening();
    } catch (e) {
      _logger.e('Fallback chat error: $e');
      
      final errorMsg = e.toString();
      bool is429 = errorMsg.contains('rate-limited') || errorMsg.contains('429');

      _safeSetState(state.copyWith(
        status: VoiceState.error, 
        errorMessage: is429 ? errorMsg : 'Connection issue. Please try again.',
        isRetrying: false,
      ));
      
      // AUTO-RECOVERY: Return to listening after 5 seconds to keep the flow alive
      await Future.delayed(const Duration(seconds: 5));
      if (!_disposed && state.status == VoiceState.error) {
        _returnToListening();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Microphone stream — started ONCE, never restarted during playback.
  // The OS keeps the mic open in playAndRecord mode so full-duplex works.
  // ---------------------------------------------------------------------------
  Future<void> _startMicStream() async {
    await _recorderSub?.cancel();

    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    final stream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 24000,
        numChannels: 1,
      ),
    );

    _recorderSub = stream.listen((chunk) {
      if (_realtimeService.isConnected) {
        _realtimeService.sendAudioChunk(chunk);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Audio buffering — just accumulate, never play mid-turn
  // ---------------------------------------------------------------------------
  void _onAudioChunk(Uint8List rawPcm) {
    if (rawPcm.isEmpty) return;
    _turnAudioBuffer.addAll(rawPcm);

    // Show speaking state as soon as first audio arrives
    if (state.status != VoiceState.speaking) {
      _safeSetState(state.copyWith(status: VoiceState.speaking, text: 'Speaking...'));
    }
  }

  // ---------------------------------------------------------------------------
  // Turn complete — wrap full turn buffer in ONE WAV and play it
  // ---------------------------------------------------------------------------
  void _onTurnComplete() {
    if (_turnAudioBuffer.isEmpty) {
      _returnToListening();
      return;
    }

    if (_isPlaying) {
      // Already playing a previous turn (shouldn't normally happen with Gemini Live,
      // but guard anyway — let existing playback finish naturally)
      return;
    }

    final wavBytes = _buildWav(Uint8List.fromList(_turnAudioBuffer));
    _turnAudioBuffer.clear();

    _playWav(wavBytes);
  }

  // ---------------------------------------------------------------------------
  // Interrupted — user spoke while AI was speaking
  // ---------------------------------------------------------------------------
  void _onInterrupted() {
    _logger.d('🛑 Interrupted — clearing audio');
    _turnAudioBuffer.clear();
    _isPlaying = false;
    _audioPlayer.stop().ignore();
    _returnToListening();
  }

  // ---------------------------------------------------------------------------
  // Play a single WAV byte array (no queuing needed — one WAV per turn)
  // ---------------------------------------------------------------------------
  Future<void> _playWav(Uint8List wavBytes) async {
    _isPlaying = true;
    try {
      await _audioPlayer.play(BytesSource(wavBytes));
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      _logger.w('Playback error (non-fatal): $e');
    } finally {
      _isPlaying = false;
      if (!_disposed) _returnToListening();
    }
  }

  void _returnToListening() {
    if (_disposed || !state.isConnected) return;

    _safeSetState(
      state.copyWith(status: VoiceState.listening, text: 'Listening...', clearError: true),
    );

    if (state.isFallbackMode) {
      _startSttListening();
    }
  }

  // ---------------------------------------------------------------------------
  // WAV builder — one call per turn (not per chunk)
  // Format: 24 kHz, mono, 16-bit PCM (Gemini Live output spec)
  // ---------------------------------------------------------------------------
  Uint8List _buildWav(Uint8List pcmData) {
    const int sampleRate = 24000;
    const int channels = 1;
    const int bitDepth = 16;
    final int byteRate = sampleRate * channels * (bitDepth ~/ 8);
    final int blockAlign = channels * (bitDepth ~/ 8);
    final int dataSize = pcmData.length;
    final int chunkSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF
    header.setUint32(0, 0x52494646, Endian.big);    // "RIFF"
    header.setUint32(4, chunkSize, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big);    // "WAVE"
    // fmt
    header.setUint32(12, 0x666d7420, Endian.big);   // "fmt "
    header.setUint32(16, 16, Endian.little);         // PCM sub-chunk size
    header.setUint16(20, 1, Endian.little);          // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitDepth, Endian.little);
    // data
    header.setUint32(36, 0x64617461, Endian.big);   // "data"
    header.setUint32(40, dataSize, Endian.little);

    final out = Uint8List(44 + dataSize);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, 44 + dataSize, pcmData);
    return out;
  }

  // ---------------------------------------------------------------------------
  // Disconnect — synchronous, no async calls, safe to call from dispose()
  // ---------------------------------------------------------------------------
  void disconnect() {
    _cancelSubscriptions(); // intentionally not awaited in dispose context
    _realtimeService.disconnect();

    // Synchronous stops — exceptions swallowed intentionally
    _audioPlayer.stop().ignore();
    _audioRecorder.stop().ignore();

    _turnAudioBuffer.clear();
    _isPlaying = false;

    _safeSetState(const VoiceSessionState(isConnected: false));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Cancel all stream subscriptions without awaiting (safe from dispose)
  Future<void> _cancelSubscriptions() async {
    await Future.wait([
      _audioSub?.cancel() ?? Future.value(),
      _textSub?.cancel() ?? Future.value(),
      _errorSub?.cancel() ?? Future.value(),
      _connectionSub?.cancel() ?? Future.value(),
      _turnCompleteSub?.cancel() ?? Future.value(),
      _interruptedSub?.cancel() ?? Future.value(),
      _recorderSub?.cancel() ?? Future.value(),
    ]);
    _audioSub = null;
    _textSub = null;
    _errorSub = null;
    _connectionSub = null;
    _turnCompleteSub = null;
    _interruptedSub = null;
    _recorderSub = null;
  }

  /// Guard all state.set calls — StateNotifier throws if you mutate after dispose
  void _safeSetState(VoiceSessionState next) {
    if (!_disposed) state = next;
  }

  // ---------------------------------------------------------------------------
  // Dispose — NEVER use ref here; NEVER await async work that calls setState
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _disposed = true;

    // Cancel subs synchronously (futures are fire-and-forget)
    _audioSub?.cancel();
    _textSub?.cancel();
    _errorSub?.cancel();
    _connectionSub?.cancel();
    _turnCompleteSub?.cancel();
    _interruptedSub?.cancel();
    _recorderSub?.cancel();

    _realtimeService.disconnect();
    _audioPlayer.stop().ignore();
    _audioPlayer.dispose();
    _audioRecorder.stop().ignore();
    _audioRecorder.dispose();

    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final voiceSessionProvider =
    StateNotifierProvider<VoiceSessionNotifier, VoiceSessionState>(
      (ref) => VoiceSessionNotifier(ref),
    );
