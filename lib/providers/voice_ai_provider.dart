import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/ai_config.dart';
import '../core/services/voice_ai_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import '../data/models/ai_intent.dart';
import '../data/models/conversation_message.dart';

/// State for voice AI interaction
class VoiceAIState {
  final bool isInitialized;
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final List<ConversationMessage> messages;
  final AIIntent? currentIntent;
  final String? error;
  final bool isMockMode;

  const VoiceAIState({
    this.isInitialized = false,
    this.isListening = false,
    this.isSpeaking = false,
    this.isProcessing = false,
    this.messages = const [],
    this.currentIntent,
    this.error,
    this.isMockMode = false,
  });

  VoiceAIState copyWith({
    bool? isInitialized,
    bool? isListening,
    bool? isSpeaking,
    bool? isProcessing,
    List<ConversationMessage>? messages,
    AIIntent? currentIntent,
    bool clearIntent = false,
    String? error,
    bool clearError = false,
    bool? isMockMode,
  }) {
    return VoiceAIState(
      isInitialized: isInitialized ?? this.isInitialized,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isProcessing: isProcessing ?? this.isProcessing,
      messages: messages ?? this.messages,
      currentIntent: clearIntent ? null : (currentIntent ?? this.currentIntent),
      error: clearError ? null : (error ?? this.error),
      isMockMode: isMockMode ?? this.isMockMode,
    );
  }
}

/// Notifier for managing voice AI state
/// Notifier for managing voice AI state
class VoiceAINotifier extends StateNotifier<VoiceAIState> {
  final VoiceAIService _service = VoiceAIService();
  final Ref ref;

  StreamSubscription<String>? _statusSubscription;

  VoiceAINotifier(this.ref) : super(const VoiceAIState());

  /// Initialize the voice AI service
  Future<void> initialize() async {
    try {
      final initialized = await _service.initialize();

      // Listen to service status stream
      _statusSubscription = _service.statusStream.listen((status) {
        switch (status) {
          case 'connected':
            // Connection established, reset processing state
            state = state.copyWith(isProcessing: false, clearError: true);
            break;
          case 'listening':
            state = state.copyWith(
              isListening: true,
              isSpeaking: false,
              isProcessing: false,
            );
            break;
          case 'speaking':
            state = state.copyWith(isSpeaking: true, isListening: false);
            break;
          case 'interrupted':
            // Interrupted, maybe go back to listening
            state = state.copyWith(isSpeaking: false);
            break;
          case 'disconnected':
            state = state.copyWith(
              isListening: false,
              isSpeaking: false,
              isProcessing: false,
            );
            break;
        }
      });

      state = state.copyWith(
        isInitialized: initialized,
        error: initialized ? null : 'Failed to initialize voice service',
      );
    } catch (e) {
      state = state.copyWith(error: 'Init error: ${e.toString()}');
    }
  }

  /// Update AI context (Private helper)
  String _getSystemPrompt() {
    final userProfile = ref.read(currentProfileProvider);
    final location = ref.read(locationProvider).valueOrNull;

    return AIConfig.getSystemPrompt(
      userProfile: userProfile,
      location: location,
    );
  }

  /// Start Live Session (Connects and Starts Streaming)
  Future<void> startSession() async {
    if (!state.isInitialized) {
      await initialize();
    }

    // Reset state
    state = state.copyWith(
      clearError: true,
      isProcessing: true,
    ); // Processing = Connecting here

    try {
      final prompt = _getSystemPrompt();
      await _service.startSession(prompt);

      // Send initial greeting after connection
      final userProfile = ref.read(currentProfileProvider);
      final userName = userProfile?.name ?? 'Friend';
      _service.sendGreeting(userName);

      // Status update will come from stream ('connected' -> 'listening')
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error:
            'Connection failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Toggle Session (Connect/Disconnect)
  Future<void> toggleSession() async {
    if (_service.isConnected) {
      await endSession();
    } else {
      await startSession();
    }
  }

  /// Stop Session
  Future<void> endSession() async {
    await _service.endSession();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}

/// Provider for voice AI state
final voiceAIProvider = StateNotifierProvider<VoiceAINotifier, VoiceAIState>((
  ref,
) {
  return VoiceAINotifier(ref);
});
