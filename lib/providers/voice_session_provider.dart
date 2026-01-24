import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:logger/logger.dart';
import '../core/services/realtime_chat_service.dart';
import '../core/services/audio_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'language_provider.dart';

enum VoiceState { initial, listening, processing, speaking, error }

class VoiceSessionState {
  final VoiceState status;
  final String text; // Transcription or Response
  final String? errorMessage;
  final String languageCode;

  VoiceSessionState({
    this.status = VoiceState.initial,
    this.text = '',
    this.errorMessage,
    this.languageCode = 'en-IN',
  });

  VoiceSessionState copyWith({
    VoiceState? status,
    String? text,
    String? errorMessage,
    String? languageCode,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      text: text ?? this.text,
      errorMessage: errorMessage ?? this.errorMessage,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class VoiceSessionNotifier extends StateNotifier<VoiceSessionState> {
  final Ref ref;

  VoiceSessionNotifier(this.ref) : super(VoiceSessionState());

  final SpeechToText _speech = SpeechToText();
  final RealtimeChatService _realtimeService = RealtimeChatService();
  final AudioService _audio = AudioService();
  final Logger _logger = Logger();

  bool _isSpeechInitialized = false;
  bool _isListening = false;
  StreamSubscription? _aiStreamSubscription;

  /// Initialize services
  Future<void> initialize() async {
    try {
      // 1. Init STT
      _isSpeechInitialized = await _speech.initialize(
        onError: (e) {
          _logger.e('STT Error: $e');
          String msg = 'Microphone error: ${e.errorMsg}';
          if (e.errorMsg.contains('network')) {
            msg =
                'Voice recognition unavailable. Check internet or use Chrome.';
          }
          state = state.copyWith(status: VoiceState.error, errorMessage: msg);
        },
        onStatus: (status) {
          _logger.d('🐛 STT Status: $status');

          if (status == 'notListening' || status == 'done') {
            _isListening = false; // 🔓 UNLOCK
          }
        },
      );

      // 2. Init TTS
      await _audio.initialize();

      // 3. Connect Realtime Service
      final userProfile = ref.read(currentProfileProvider);
      final location = ref.read(locationProvider).valueOrNull;
      final languageState = ref.read(languageProvider);

      await _realtimeService.connect(
        userProfile: userProfile,
        location: location,
        appLanguage: languageState.locale.languageCode,
      );

      // 4. Listen to AI responses
      _aiStreamSubscription = _realtimeService.responseStream.listen((chunk) {
        _handleAiChunk(chunk);
      });

      // 5. Listen for Turn Complete
      _realtimeService.turnCompleteStream.listen((_) {
        _logger.d('🛑 Turn Complete Signal Received');
        _speakBuffer(force: true);
      });
    } catch (e) {
      _logger.e('Init Error: $e');
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: 'Failed to initialize voice services',
      );
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    // 🔒 HARD GUARD (MOST IMPORTANT)
    if (_isListening) {
      _logger.w('⚠️ STT already listening, ignoring startListening');
      return;
    }

    if (state.status == VoiceState.speaking ||
        state.status == VoiceState.processing) {
      _logger.w('⚠️ Cannot listen while ${state.status}');
      return;
    }

    if (!_isSpeechInitialized) {
      await initialize();
    }

    // Removed invalid hasSpeech check.
    // Usually initialize returns false if not available/supported.

    _logger.i('🎤 START LISTENING');

    _isListening = true; // 🔐 LOCK

    state = state.copyWith(status: VoiceState.listening, text: '');
    await _audio.stop();

    final langState = ref.read(languageProvider);
    String localeId = langState.locale.languageCode == 'hi' ? 'hi_IN' : 'en_IN';

    _speech.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 2),
      cancelOnError: true,
      onResult: (result) {
        _logger.i(
          '🗣️ Speech: ${result.recognizedWords}, final=${result.finalResult}',
        );

        state = state.copyWith(text: result.recognizedWords);

        if (result.finalResult) {
          _processQuery(result.recognizedWords);
        }
      },
    );
  }

  /// Stop listening manually
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    state = state.copyWith(status: VoiceState.initial);
  }

  /// Send text to Gemini
  void _processQuery(String query) {
    if (query.trim().isEmpty) return;

    // Prevent double processing
    if (state.status == VoiceState.processing) return;

    _logger.i('➡️ Sending to AI: $query');
    state = state.copyWith(status: VoiceState.processing);

    // Send to WebSocket
    _realtimeService.sendTextMessage(query);

    // Reset text to empty to accumulate response
    state = state.copyWith(text: '');
  }

  String _buffer = '';

  /// Handle incoming AI text chunks
  void _handleAiChunk(String chunk) {
    if (chunk.isEmpty) return;

    _logger.i('🤖 AI chunk: $chunk');

    // Append to buffer and display state
    _buffer += chunk;
    state = state.copyWith(status: VoiceState.speaking, text: _buffer);

    // Simple sentence detection to speak chunks naturally
    if (chunk.contains('.') ||
        chunk.contains('?') ||
        chunk.contains('!') ||
        chunk.contains('।')) {
      _speakBuffer();
    }
  }

  Future<void> _speakBuffer({bool force = false}) async {
    // Only return if empty AND not forcing (though if empty, nothing to speak anyway)
    // But checking isEmpty is enough. If force is true, we still need text.
    if (_buffer.trim().isEmpty) return;

    // Logic: If prompt says "if (_buffer.trim().isEmpty && !force) return;",
    // it implies we might speak empty text? No, it implies we wait for punctuation.
    // Actually, user said: "if (_buffer.trim().isEmpty && !force) return;"
    // which means if it IS empty, we return unless forced? No, empty text is silence.
    // The user meant "if I don't have a full sentence buffer, don't speak, UNLESS forced".
    // But my buffer accumulation logic above calls this only on punctuation.
    // Let's implement the force logic for the "Turn Complete" scenario.

    // Wait, the user said:
    // Future<void> _speakBuffer({bool force = false}) async {
    //   if (_buffer.trim().isEmpty && !force) return;

    // This implies if buffer is NOT empty, we proceed.
    // If buffer IS empty, and NOT force, we return.
    // If buffer IS empty, and FORCE is true, we proceed? (To speak empty string?)
    // Likely the user intended: "Use force to bypass checks".
    // But checking "isEmpty" is fundamental.

    // Let's assume the user wants:
    // "Don't speak partial chunks unless forced".
    // But I am calling this method only on punctuation OR force.
    // So the check `if (_buffer.trim().isEmpty) return;` is fine.

    final textToSpeak = _buffer;
    _buffer =
        ''; // Clear buffer BEFORE speaking to avoid double-speak if called again

    // Detect Language for TTS
    bool isHindi = textToSpeak.codeUnits.any((c) => c >= 0x0900 && c <= 0x097F);
    String langCode = isHindi ? 'hi-IN' : 'en-IN';

    await _audio.setLanguage(langCode);
    await _audio.speak(textToSpeak);

    // Reset state after speaking (unless streaming continues, but we usually want to listen again)
    // Actually, streaming might continue. But user requested:
    state = state.copyWith(status: VoiceState.initial);
    _isListening = false; // safety
  }

  void reset() {
    _audio.stop();
    _speech.stop();
    _realtimeService.disconnect();
    _aiStreamSubscription?.cancel();
    state = VoiceSessionState();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

final voiceSessionProvider =
    StateNotifierProvider<VoiceSessionNotifier, VoiceSessionState>((ref) {
      return VoiceSessionNotifier(ref);
    });
