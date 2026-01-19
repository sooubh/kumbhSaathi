import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:logger/logger.dart';
import '../core/services/gemini_service.dart';
import '../core/services/audio_service.dart';
import '../core/services/realtime_crowd_service.dart';
import '../core/config/ai_config.dart';

enum VoiceState { initial, listening, processing, speaking, error }

class VoiceSessionState {
  final VoiceState status;
  final String text; // Transcription or Response
  final String? errorMessage;

  VoiceSessionState({
    this.status = VoiceState.initial,
    this.text = '',
    this.errorMessage,
  });

  VoiceSessionState copyWith({
    VoiceState? status,
    String? text,
    String? errorMessage,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      text: text ?? this.text,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VoiceSessionNotifier extends StateNotifier<VoiceSessionState> {
  VoiceSessionNotifier() : super(VoiceSessionState());

  final SpeechToText _speech = SpeechToText();
  final GeminiService _gemini = GeminiService();
  final AudioService _audio = AudioService();
  final Logger _logger = Logger();
  bool _isSpeechInitialized = false;

  /// Initialize services
  Future<void> initialize() async {
    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (e) {
          _logger.e('STT Error: $e');
          state = state.copyWith(
            status: VoiceState.error,
            errorMessage: 'Microphone error: ${e.errorMsg}',
          );
        },
        onStatus: (status) {
          _logger.d('STT Status: $status');
          if (status == 'notListening' || status == 'done') {
            if (state.status == VoiceState.listening && state.text.isNotEmpty) {
              _processQuery(state.text);
            }
          }
        },
      );
      await _audio.initialize();
      _gemini.initialize();
    } catch (e) {
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: 'Failed to initialize voice services',
      );
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!_isSpeechInitialized) {
      await initialize();
    }

    if (_isSpeechInitialized) {
      state = state.copyWith(status: VoiceState.listening, text: '');
      await _audio.stop(); // Stop any current audio

      _speech.listen(
        onResult: (result) {
          state = state.copyWith(text: result.recognizedWords);
          if (result.finalResult) {
            _processQuery(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
        cancelOnError: true,
      );
    } else {
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: 'Speech recognition not available',
      );
    }
  }

  /// Stop listening manually
  Future<void> stopListening() async {
    await _speech.stop();
    if (state.status == VoiceState.listening && state.text.isNotEmpty) {
      // If we have text but it wasn't marked final yet
      _processQuery(state.text);
    } else {
      state = state.copyWith(status: VoiceState.initial);
    }
  }

  /// Process the query with Gemini
  Future<void> _processQuery(String query) async {
    if (query.isEmpty) return;

    state = state.copyWith(status: VoiceState.processing);
    await _speech.stop();

    try {
      // 1. Fetch Dynamic Context (Crowd Stats)
      final crowdStats = await RealtimeCrowdService().getCrowdStats();

      // 2. Construct System Context Message
      // We prepend this to the user's query to ensure the AI has the latest data
      final systemContext = AIConfig.getSystemPrompt(
        crowdStats: crowdStats,
        // TODO: Pass actual user profile and location when available
      );

      final fullMessage = '$systemContext\n\nUSER QUERY: $query';
      _logger.d('Sending to Gemini with Context:\n$fullMessage');

      // 3. Send to Gemini
      final response = await _gemini.sendMessage(fullMessage);

      // 4. Parse Language Tag (e.g., [hi] or [en])
      String cleanResponse = response;
      String languageCode = "en-IN"; // Default

      if (response.contains('[hi]')) {
        languageCode = "hi-IN";
        cleanResponse = response.replaceAll('[hi]', '').trim();
      } else if (response.contains('[en]')) {
        languageCode = "en-IN";
        cleanResponse = response.replaceAll('[en]', '').trim();
      }

      state = state.copyWith(status: VoiceState.speaking, text: cleanResponse);

      // 5. Speak with correct language
      await _audio.setLanguage(languageCode);
      await _audio.speak(cleanResponse);

      // Reset to initial after speech (or let user manually restart)
    } catch (e) {
      state = state.copyWith(
        status: VoiceState.error,
        errorMessage: 'Sorry, I encountered an error.',
      );
      await _audio.speak("Sorry, I encountered an error.");
    }
  }

  void reset() {
    _audio.stop();
    _speech.stop();
    state = VoiceSessionState();
  }
}

final voiceSessionProvider =
    StateNotifierProvider<VoiceSessionNotifier, VoiceSessionState>((ref) {
      return VoiceSessionNotifier();
    });
