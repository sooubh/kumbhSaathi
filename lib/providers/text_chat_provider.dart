import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/models/conversation_message.dart';
import '../core/config/ai_config.dart';
import '../core/services/text_chat_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'language_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Notifier — uses the Gemini REST generateContent API for text chat.
//
// WHY NOT WEBSOCKET:
//   The Live WebSocket endpoint is optimised for real-time AUDIO streaming.
//   Requesting TEXT modality over it is unreliable and responds slowly.
//   The standard REST API is the correct, stable choice for a text chatbot.
// ---------------------------------------------------------------------------

class TextChatNotifier extends StateNotifier<TextChatState> {
  final Ref _ref;

  final TextChatService _textChatService = TextChatService();
  bool _disposed = false;

  TextChatNotifier(this._ref) : super(const TextChatState());

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    // 1. Immediately show the user's message and lock the input
    final userMsg = ConversationMessage.user(trimmed);
    _safeSetState(
      state.copyWith(
        messages: [...state.messages, userMsg],
        isLoading: true,
        isTyping: true,
        clearError: true,
      ),
    );

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

      if (_disposed) return;

      // 3. Add the assistant reply
      final assistantMsg = response;

      _safeSetState(
        state.copyWith(
          messages: [...state.messages, assistantMsg],
          isLoading: false,
          isTyping: false,
        ),
      );
    } catch (e) {
      if (_disposed) return;

      _safeSetState(
        state.copyWith(
          isLoading: false,
          isTyping: false,
          error: _friendlyError(e),
        ),
      );
    } finally {
      if (!_disposed) {
        _safeSetState(state.copyWith(isLoading: false, isTyping: false));
      }
    }
  }

  void clearChat() {
    _textChatService.clearHistory();
    _safeSetState(const TextChatState());
  }

  void clearError() => _safeSetState(state.copyWith(clearError: true));

  // _callGemini method removed in favor of TextChatService

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _friendlyError(Object e) {
    final msg = e.toString();
    
    // Pass through already friendly messages from TextChatService
    if (msg.contains('rate-limited') || msg.contains('temporarily busy')) {
      return msg.replaceAll('Exception: ', '');
    }

    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('API key')) {
      return 'AI service is not configured. Contact support.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _safeSetState(TextChatState next) {
    if (!_disposed) state = next;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final textChatProvider =
    StateNotifierProvider<TextChatNotifier, TextChatState>(
  (ref) => TextChatNotifier(ref),
);
