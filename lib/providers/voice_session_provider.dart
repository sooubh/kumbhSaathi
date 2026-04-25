import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart' as audio_session;
import '../core/services/realtime_chat_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'language_provider.dart';

enum VoiceState { initial, connecting, listening, speaking, error }

class VoiceSessionState {
  final VoiceState status;
  final String text; // Transcript (if available) or status message
  final String? errorMessage;
  final bool isConnected;
  final bool isSpeakerOn;

  VoiceSessionState({
    this.status = VoiceState.initial,
    this.text = '',
    this.errorMessage,
    this.isConnected = false,
    this.isSpeakerOn = true,
  });

  VoiceSessionState copyWith({
    VoiceState? status,
    String? text,
    String? errorMessage,
    bool? isConnected,
    bool? isSpeakerOn,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      text: text ?? this.text,
      errorMessage: errorMessage ?? this.errorMessage,
      isConnected: isConnected ?? this.isConnected,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    );
  }
}

class VoiceSessionNotifier extends StateNotifier<VoiceSessionState> {
  final Ref ref;

  VoiceSessionNotifier(this.ref) : super(VoiceSessionState());

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer(); // For playing AI response
  // We might need a more low-level player for PCM streaming (like sound_stream or just flutter_pcm_sound)
  // Standard AudioPlayer doesn't support raw PCM stream easily without converting to WAV.
  // However, for this implementation, since we need to move fast, we can try to accumulate chunks and play,
  // BUT the provided `voicechat.md` example used `audioplayers`?
  // Wait, the user's `voicechat.md` example for "Live Voice Chat" used `AudioPlayer` but didn't show the `_buffer` logic for *playback*, only for *sending*.
  // Actually, standard AudioPlayer handles files/urls well. For raw PCM, `audioplayers` 6.0 might not be enough for *streaming* raw bytes directly without a custom source.
  // BUT, let's look at what I promised: "Implement continuous listening from RealtimeChatService -> AudioPlayer".
  // A common trick is to write the PCM to a temporary WAV file and play it, or use a specific PCM player.
  // Attempting to use a simple queue of SourceBytes if possible, or fall back to WAV header injection.
  // For simplicity and robustness given instructions, I will assume we might need to queue audio or use a simple wav header wrapper.

  final RealtimeChatService _realtimeService = RealtimeChatService();
  final Logger _logger = Logger();

  StreamSubscription? _audioSubscription;
  StreamSubscription? _turnCompleteSubscription;
  StreamSubscription? _recorderSubscription;

  // Audio Buffering
  final List<int> _currentAudioBuffer = [];
  final int _minBufferSize =
      24000; // ~0.5 seconds at 24kHz 16-bit mono (48000 bytes/s -> 0.5s = 24000 bytes)
  // Actually: 24000 samples * 2 bytes/sample = 48000 bytes/sec. So 24000 bytes is 0.5s.

  final List<Uint8List> _audioQueue = [];
  bool _isPlaying = false;

  /// Initialize Audio Session & Player Context
  Future<void> _configureAudioSession() async {
    try {
      // 1. Configure Low-Level Audio Session (audio_session)
      final session = await audio_session.AudioSession.instance;

      // Force Speakerphone options
      final options =
          audio_session.AVAudioSessionCategoryOptions.defaultToSpeaker |
          audio_session.AVAudioSessionCategoryOptions.allowBluetooth |
          audio_session.AVAudioSessionCategoryOptions.allowBluetoothA2dp;

      await session.configure(
        audio_session.AudioSessionConfiguration(
          avAudioSessionCategory:
              audio_session.AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions: options,
          avAudioSessionMode: audio_session
              .AVAudioSessionMode
              .videoChat, // videoChat often forces speaker better than voiceChat
          avAudioSessionRouteSharingPolicy:
              audio_session.AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions:
              audio_session.AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: audio_session.AndroidAudioAttributes(
            contentType: audio_session.AndroidAudioContentType.speech,
            flags: audio_session.AndroidAudioFlags.none,
            usage: audio_session.AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType:
              audio_session.AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      // 2. Configure AudioPlayers specific context to match
      // Switching to 'media' usage often forces speaker better than 'voiceCommunication' on some Android devices
      // even if we are doing voice chat.
      final playerContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType
              .media, // CHANGED from voiceCommunication to media to force speaker
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
      );
      await _audioPlayer.setAudioContext(playerContext);

      _logger.d('✅ Audio Session Configured (Forced Speaker)');
    } catch (e) {
      _logger.e('❌ Failed to configure Audio Session: $e');
    }
  }

  /// Initialize and Connect
  Future<void> connect() async {
    try {
      state = state.copyWith(
        status: VoiceState.connecting,
        text: 'Connecting to Gemini...',
      );

      _audioQueue.clear();
      _currentAudioBuffer.clear();

      // 0. Configure Audio Session (Important for full duplex)
      await _configureAudioSession();

      // 1. Permissions are checked in UI, but good to be safe
      if (!await _audioRecorder.hasPermission()) {
        state = state.copyWith(
          status: VoiceState.error,
          errorMessage: 'Microphone permission denied',
        );
        return;
      }

      // 2. Connect Realtime Service
      final userProfile = ref.read(currentProfileProvider);
      final location = ref.read(locationProvider).valueOrNull;
      final languageState = ref.read(languageProvider);

      await _realtimeService.connect(
        userProfile: userProfile,
        location: location,
        appLanguage: languageState.locale.languageCode,
      );

      // 3. Listen to AI Audio Stream
      _audioSubscription = _realtimeService.audioStream.listen((audioBytes) {
        _bufferAudio(audioBytes);
      });

      // 4. Listen to Turn Complete
      _turnCompleteSubscription = _realtimeService.turnCompleteStream.listen((
        _,
      ) {
        _logger.d('🤖 Turn Complete');
        _flushAudioBuffer();
      });

      // 5. Start Recording & Streaming
      await _startRecordingStream();

      state = state.copyWith(
        status: VoiceState.listening,
        isConnected: true,
        text: 'Listening...',
      );
    } catch (e) {
      _logger.e('Init Error: $e');
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: 'Failed to connect: $e',
      );
    }
  }

  Future<void> _startRecordingStream() async {
    try {
      // Ensure clean state
      await _recorderSubscription?.cancel();
      // await _audioRecorder.stop(); // Stop potential existing stream
      // Actually stopping might be slow. Let's just try to start, if it fails, we catch.
      // But for robust "restart", we should stop.
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _recorderSubscription = stream.listen((data) {
        // Send data to WebSocket
        if (state.isConnected) {
          _realtimeService.sendAudioChunk(data);
        }
      });
      _logger.d('🎙️ Microphone Stream Started');

      // CRITICAL: Re-configure audio session to force speakerphone
      // The 'record' package might reset audio category to 'record' defaults (earpiece)
      await _configureAudioSession();
    } catch (e) {
      _logger.e('Error starting stream: $e');
    }
  }

  void _bufferAudio(Uint8List rawPcmData) {
    if (rawPcmData.isEmpty) return;

    state = state.copyWith(
      status: VoiceState.speaking,
      text: 'Gemini Speaking...',
    );

    _currentAudioBuffer.addAll(rawPcmData);

    // If buffer is large enough, queue it
    if (_currentAudioBuffer.length >= _minBufferSize) {
      _flushAudioBuffer();
    }
  }

  void _flushAudioBuffer() {
    if (_currentAudioBuffer.isEmpty) return;

    final chunk = Uint8List.fromList(_currentAudioBuffer);
    _currentAudioBuffer.clear();

    _audioQueue.add(chunk);

    if (!_isPlaying) {
      _playNextChunk();
    }
  }

  Future<void> _playNextChunk() async {
    if (_audioQueue.isEmpty) {
      _isPlaying = false;
      // Only switch back to listening if we really are done (queue empty AND buffer empty)
      if (_currentAudioBuffer.isEmpty) {
        state = state.copyWith(
          status: VoiceState.listening,
          text: 'Listening...',
        );

        // CRITICAL FIX: Restart recording stream just in case OS killed it during playback
        if (state.isConnected) {
          await _startRecordingStream();
        }
      }
      return;
    }

    _isPlaying = true;
    final chunk = _audioQueue.removeAt(0);

    try {
      // Create a WAV header for this chunk (24kHz, 1 channel, 16-bit)
      final wavBytes = _createWavHeader(chunk);

      // Ensure session is active before playing
      // await _configureAudioSession(); // Might be too heavy to do every chunk, skip.

      await _audioPlayer.play(BytesSource(wavBytes));

      // Wait for completion
      await _audioPlayer.onPlayerComplete.first;

      _playNextChunk();
    } catch (e) {
      _logger.e('Error playing chunk: $e');
      _isPlaying = false;
      _playNextChunk(); // Try next
    }
  }

  /// Helper to add WAV header to raw PCM data
  Uint8List _createWavHeader(Uint8List pcmData) {
    var channels = 1;
    var sampleRate = 24000; // Gemini response is usually 24kHz
    var byteRate = sampleRate * channels * 2;
    // ... basic header construction ...
    // Actually, Gemini 2.0 Flash output is often 24kHz. Input 16kHz.

    // Constructing a minimal WAY header
    var header = Uint8List(44);
    var view = ByteData.view(header.buffer);

    // RIFF check
    view.setUint32(0, 0x52494646, Endian.big); // RIFF
    view.setUint32(4, 36 + pcmData.length, Endian.little);
    view.setUint32(8, 0x57415645, Endian.big); // WAVE

    // fmt chunk
    view.setUint32(12, 0x666d7420, Endian.big); // fmt
    view.setUint32(16, 16, Endian.little); // chunk size
    view.setUint16(20, 1, Endian.little); // audio format (1 = PCM)
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, channels * 2, Endian.little); // block align
    view.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    view.setUint32(36, 0x64617461, Endian.big); // data
    view.setUint32(40, pcmData.length, Endian.little);

    var wav = Uint8List(44 + pcmData.length);
    wav.setRange(0, 44, header);
    wav.setRange(44, 44 + pcmData.length, pcmData);
    return wav;
  }

  Future<void> disconnect() async {
    _recorderSubscription?.cancel();
    _audioSubscription?.cancel();
    _turnCompleteSubscription?.cancel();
    _realtimeService.disconnect();
    await _audioRecorder.stop();
    await _audioPlayer.stop();
    _audioQueue.clear();
    _isPlaying = false;
    state = VoiceSessionState(isConnected: false);
  }

  void toggleMic() {
    // Implement mute logic if needed
  }

  @override
  void dispose() {
    disconnect();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

final voiceSessionProvider =
    StateNotifierProvider<VoiceSessionNotifier, VoiceSessionState>((ref) {
      return VoiceSessionNotifier(ref);
    });
