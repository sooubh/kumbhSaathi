import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/text_chat_service.dart';
import '../data/models/conversation_message.dart';
import 'auth_provider.dart';
import 'location_provider.dart';

/// State for text chat
class TextChatState {
  final List<ConversationMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;

  const TextChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
  });

  TextChatState copyWith({
    List<ConversationMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
    bool clearError = false,
  }) {
    return TextChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for text chat state management
class TextChatNotifier extends StateNotifier<TextChatState> {
  final TextChatService _service = TextChatService();
  final Ref ref;

  TextChatNotifier(this.ref) : super(const TextChatState());

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = ConversationMessage.user(message.trim());
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      isTyping: true,
      clearError: true,
    );

    try {
      // Get user context
      final userProfile = ref.read(currentProfileProvider);
      final location = ref.read(locationProvider).valueOrNull;

      // Get AI response
      final aiResponse = await _service.sendMessage(
        message.trim(),
        userProfile: userProfile,
        location: location,
      );

      // Add AI response to messages
      state = state.copyWith(
        messages: [...state.messages, aiResponse],
        isLoading: false,
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  /// Clear all messages and start fresh
  void clearChat() {
    _service.clearHistory();
    state = const TextChatState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Check if service is ready
  bool get isReady => _service.isReady;
}

/// Provider for text chat
final textChatProvider = StateNotifierProvider<TextChatNotifier, TextChatState>(
  (ref) {
    return TextChatNotifier(ref);
  },
);
