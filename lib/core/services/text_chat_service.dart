import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/ai_config.dart';
import '../../data/models/conversation_message.dart';

/// Service for text-based chat with Gemini 2.0 Flash
class TextChatService {
  final _logger = Logger();
  final List<ConversationMessage> _conversationHistory = [];

  // Using Gemini 2.0 Flash for fast text responses
  static const String _modelName = 'gemini-2.0-flash-exp';

  String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=${AIConfig.apiKey}';

  /// Send a text message and get AI response
  Future<ConversationMessage> sendMessage(
    String userMessage, {
    dynamic userProfile,
    dynamic location,
  }) async {
    try {
      // Add user message to history
      final userMsg = ConversationMessage.user(userMessage);
      _conversationHistory.add(userMsg);

      // Build request with conversation context
      final requestBody = _buildRequestBody(
        userMessage,
        userProfile: userProfile,
        location: location,
      );

      _logger.d('📤 Sending text message to Gemini 2.0 Flash');

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = _parseResponse(data);

        // Add AI response to history
        final assistantMsg = ConversationMessage.assistant(aiResponse);
        _conversationHistory.add(assistantMsg);

        _logger.d('✅ Received AI response: ${aiResponse.substring(0, 50)}...');
        return assistantMsg;
      } else {
        _logger.e('❌ API Error: ${response.statusCode} - ${response.body}');
        throw 'Failed to get response from AI (${response.statusCode})';
      }
    } catch (e) {
      _logger.e('❌ TextChatService Error: $e');
      throw 'Failed to send message: $e';
    }
  }

  /// Build request body for Gemini API
  Map<String, dynamic> _buildRequestBody(
    String userMessage, {
    dynamic userProfile,
    dynamic location,
  }) {
    // Get system prompt with context
    final systemPrompt = AIConfig.getSystemPrompt(
      userProfile: userProfile,
      location: location,
    );

    // Build contents array with conversation history
    final contents = <Map<String, dynamic>>[];

    // Add conversation history (last 10 messages to keep context manageable)
    final recentHistory = _conversationHistory.length > 10
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;

    for (final msg in recentHistory) {
      contents.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content},
        ],
      });
    }

    return {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        },
      ],
    };
  }

  /// Parse AI response from API
  String _parseResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return 'Sorry, I could not generate a response.';
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List<dynamic>?;

      if (parts == null || parts.isEmpty) {
        return 'Sorry, I could not generate a response.';
      }

      final text = parts[0]['text'] as String?;
      return text ?? 'Sorry, I could not understand that.';
    } catch (e) {
      _logger.e('Failed to parse response: $e');
      return 'Sorry, there was an error processing the response.';
    }
  }

  /// Get conversation history
  List<ConversationMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
    _logger.d('🗑️ Conversation history cleared');
  }

  /// Check if service is ready
  bool get isReady => AIConfig.apiKey.isNotEmpty;
}
