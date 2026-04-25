import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../data/models/conversation_message.dart';
import '../core/config/ai_config.dart';
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

  // In-memory conversation history sent to the API on every turn
  // (gives the model multi-turn context)
  final List<Map<String, dynamic>> _history = [];

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

    // 2. Append to history (Gemini expects alternating user/model turns)
    _history.add({
      'role': 'user',
      'parts': [
        {'text': trimmed}
      ],
    });

    try {
      final response = await _callGemini();

      if (_disposed) return;

      // 3. Add the assistant reply
      final assistantMsg = ConversationMessage.assistant(response);
      _history.add({
        'role': 'model',
        'parts': [
          {'text': response}
        ],
      });

      _safeSetState(
        state.copyWith(
          messages: [...state.messages, assistantMsg],
          isLoading: false,
          isTyping: false,
        ),
      );
    } catch (e) {
      if (_disposed) return;

      // Roll back history on failure so the next send isn't confused
      if (_history.isNotEmpty) _history.removeLast();

      _safeSetState(
        state.copyWith(
          isLoading: false,
          isTyping: false,
          error: _friendlyError(e),
        ),
      );
    }
  }

  void clearChat() {
    _history.clear();
    _safeSetState(const TextChatState());
  }

  void clearError() => _safeSetState(state.copyWith(clearError: true));

  // ---------------------------------------------------------------------------
  // Gemini REST call — generateContent (single-turn with history)
  // ---------------------------------------------------------------------------

  Future<String> _callGemini() async {
    final apiKey = AIConfig.apiKey;
    if (apiKey.isEmpty) {
      throw Exception('Gemini API key is not configured.');
    }

    // Read context providers (safe here — this method is always called from sendMessage
    // while the notifier is alive)
    final userProfile = _ref.read(currentProfileProvider);
    final location = _ref.read(locationProvider).valueOrNull;
    final language = _ref.read(languageProvider);

    final systemPrompt = AIConfig.getSystemPrompt(
      userProfile: userProfile,
      location: location,
      appLanguage: language.locale.languageCode,
    );

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/${AIConfig.modelName}:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ],
      },
      'contents': _history,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topP': 0.95,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE'
        },
      ],
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body);
      final msg = decoded['error']?['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception('Gemini API error: $msg');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates.');
    }

    final parts = candidates.first['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }

    return (parts.first['text'] as String? ?? '').trim();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _friendlyError(Object e) {
    final msg = e.toString();
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
