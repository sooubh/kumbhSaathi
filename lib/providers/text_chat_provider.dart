import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/realtime_chat_service.dart';
import '../data/models/conversation_message.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'language_provider.dart';

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
  final Ref ref;
  final RealtimeChatService _service = RealtimeChatService();
  StreamSubscription? _aiSubscription;
  String _currentResponseBuffer = '';

  TextChatNotifier(this.ref) : super(const TextChatState());

  /// Initialize connection if needed
  Future<void> _ensureConnected() async {
    if (!_service.isConnected) {
      final userProfile = ref.read(currentProfileProvider);
      final location = ref.read(locationProvider).valueOrNull;
      final languageState = ref.read(languageProvider);

      await _service.connect(
        userProfile: userProfile,
        location: location,
        appLanguage: languageState.locale.languageCode,
        responseModalities: ['TEXT'], // Request Text for Chat
      );

      // Listen to stream
      _aiSubscription = _service.textStream.listen((chunk) {
        _handleAiResponse(chunk);
      });
    }
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      await _ensureConnected();

      // Add user message immediately
      final userMessage = ConversationMessage.user(message.trim());
      state = state.copyWith(
        messages: [...state.messages, userMessage],
        isLoading: true,
        isTyping: true,
        clearError: true,
      );

      // Reset buffer for new response
      _currentResponseBuffer = '';

      // Send to WebSocket
      _service.sendTextMessage(message.trim());

      // We don't await response here as it comes via stream
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  void _handleAiResponse(String chunk) {
    if (chunk.isEmpty) return;

    _currentResponseBuffer += chunk;

    // Check if we already have a pending AI message (last message is assistant)
    // If so, update it. If not (first chunk), add it.

    List<ConversationMessage> newMessages;
    final lastMsg = state.messages.isNotEmpty ? state.messages.last : null;

    if (lastMsg != null &&
        lastMsg.role == MessageRole.assistant &&
        state.isLoading) {
      // Update existing assistant message (streaming)
      final updatedMsg = ConversationMessage(
        role: MessageRole.assistant,
        content: _currentResponseBuffer,
        timestamp: lastMsg.timestamp,
      );

      newMessages = List.from(state.messages)
        ..removeLast()
        ..add(updatedMsg);
    } else {
      // First chunk of new response
      final newMsg = ConversationMessage.assistant(_currentResponseBuffer);
      newMessages = [...state.messages, newMsg];
    }

    state = state.copyWith(
      messages: newMessages,
      isLoading: true, // Still loading until we decide it's done?
      // For Chat UI, let's keep it true to show "active" state or false if we just want to show text.
      // Usually streaming implies active generation.
      isTyping: false,
    );
    // Note: In a real app we'd want 'turnComplete' from WebSocket to set isLoading = false.
    // For now, we assume if we are getting text, it's loading.
    // We can implement a timeout or just leave it.
    // Or assuming the user will reply again?
    // Let's rely on the stream.
  }

  /// Clear all messages and start fresh
  void clearChat() {
    state = const TextChatState();
    _currentResponseBuffer = '';
    // Optional: disconnect
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _aiSubscription?.cancel();
    _service.disconnect();
    super.dispose();
  }
}

/// Provider for text chat
final textChatProvider = StateNotifierProvider<TextChatNotifier, TextChatState>(
  (ref) {
    return TextChatNotifier(ref);
  },
);
