import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import '../config/ai_config.dart';
import '../../data/models/conversation_message.dart';

/// Service for interacting with Google Gemini AI
class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chat;
  final List<ConversationMessage> _conversationHistory = [];
  final _logger = Logger();

  bool get isInitialized => _model != null;
  bool get isMockMode => AIConfig.useMockMode;
  List<ConversationMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Initialize the Gemini model
  Future<void> initialize({String? systemPrompt}) async {
    if (isMockMode) {
      _logger.i('🤖 GeminiService: Running in MOCK mode (no API key provided)');
      return;
    }

    try {
      _model = GenerativeModel(
        model: AIConfig.modelName,
        apiKey: AIConfig.apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );

      // Start a new chat session with system prompt
      final prompt = systemPrompt ?? AIConfig.getSystemPrompt();
      _chat = _model!.startChat(history: [Content.text(prompt)]);

      _logger.i('✅ GeminiService: Initialized successfully');
    } catch (e) {
      _logger.e('❌ GeminiService: Failed to initialize - $e');
      rethrow;
    }
  }

  /// Send a message and get AI response
  Future<String> sendMessage(String message) async {
    // Add user message to history
    _conversationHistory.add(ConversationMessage.user(message));

    if (isMockMode) {
      return _getMockResponse(message);
    }

    if (_chat == null) {
      await initialize();
    }

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      final aiResponse =
          response.text ?? 'I apologize, but I could not generate a response.';

      // Add AI response to history
      _conversationHistory.add(ConversationMessage.assistant(aiResponse));

      return aiResponse;
    } catch (e) {
      _logger.e('❌ GeminiService: Error sending message - $e');
      final errorResponse = 'I encountered an error. Please try again.';
      _conversationHistory.add(ConversationMessage.assistant(errorResponse));
      return errorResponse;
    }
  }

  /// Get mock response for testing without API key
  String _getMockResponse(String message) {
    final lowerMessage = message.toLowerCase();

    String response;
    if (lowerMessage.contains('lost') || lowerMessage.contains('missing')) {
      if (_conversationHistory.length <= 2) {
        response = AIConfig.mockResponses['lost_person_initial']!;
      } else if (!_hasCollected('age')) {
        response = AIConfig.mockResponses['lost_person_age']!;
      } else if (!_hasCollected('height')) {
        response = AIConfig.mockResponses['lost_person_height']!;
      } else if (!_hasCollected('clothing')) {
        response = AIConfig.mockResponses['lost_person_clothing']!;
      } else if (!_hasCollected('location')) {
        response = AIConfig.mockResponses['lost_person_location']!;
      } else {
        response = _buildMockCompleteResponse();
      }
    } else if (lowerMessage.contains('navigate') ||
        lowerMessage.contains('take me')) {
      response = AIConfig.mockResponses['navigation']!;
    } else if (lowerMessage.contains('emergency') ||
        lowerMessage.contains('help')) {
      response = AIConfig.mockResponses['sos']!;
    } else {
      response = AIConfig.mockResponses['general']!;
    }

    // Add AI response to history
    _conversationHistory.add(ConversationMessage.assistant(response));
    return response;
  }

  bool _hasCollected(String field) {
    // Simple check - in real mock mode, you'd track collected fields
    return _conversationHistory.length > 5;
  }

  String _buildMockCompleteResponse() {
    // Extract data from conversation history
    final data = _extractMockData();
    return '''
{
  "intent": "report_lost_person",
  "confidence": 0.95,
  "data": {
    "name": "${data['name'] ?? 'Unknown'}",
    "age": ${data['age'] ?? 0},
    "gender": "${data['gender'] ?? 'Unknown'}",
    "height": "${data['height'] ?? ''}",
    "clothing": "${data['clothing'] ?? ''}",
    "lastSeenLocation": "${data['location'] ?? ''}",
    "guardianName": "${data['guardianName'] ?? ''}",
    "guardianRelation": "${data['guardianRelation'] ?? ''}"
  },
  "missingFields": [],
  "nextQuestion": ""
}
''';
  }

  Map<String, dynamic> _extractMockData() {
    // Very basic extraction for demo - real implementation would be more sophisticated
    final data = <String, dynamic>{};
    for (var msg in _conversationHistory.where(
      (m) => m.role == MessageRole.user,
    )) {
      final content = msg.content;
      // Extract name if mentioned
      if (content.toLowerCase().contains('name is')) {
        final parts = content.split('name is');
        if (parts.length > 1) {
          data['name'] = parts[1]
              .trim()
              .split(' ')
              .first
              .replaceAll(RegExp(r'[^a-zA-Z]'), '');
        }
      }
      // Extract age
      final ageMatch = RegExp(
        r'\b(\d{1,3})\s*(?:years?|old)\b',
      ).firstMatch(content.toLowerCase());
      if (ageMatch != null) {
        data['age'] = int.tryParse(ageMatch.group(1)!) ?? 0;
      }
      // Extract guardian
      if (content.toLowerCase().contains('father') ||
          content.toLowerCase().contains('mother')) {
        final parts = content.split(' ');
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].toLowerCase() == 'father' && i > 0) {
            data['guardianName'] = parts[i - 1].replaceAll(
              RegExp(r'[^a-zA-Z]'),
              '',
            );
            data['guardianRelation'] = 'father';
          } else if (parts[i].toLowerCase() == 'mother' && i > 0) {
            data['guardianName'] = parts[i - 1].replaceAll(
              RegExp(r'[^a-zA-Z]'),
              '',
            );
            data['guardianRelation'] = 'mother';
          }
        }
      }
    }
    return data;
  }

  /// Clear conversation history and start fresh
  void clearConversation({String? systemPrompt}) {
    _conversationHistory.clear();
    if (!isMockMode && _model != null) {
      final prompt = systemPrompt ?? AIConfig.getSystemPrompt();
      _chat = _model!.startChat(history: [Content.text(prompt)]);
    }
  }

  /// Start a new chat with updated system prompt
  void startNewChat(String systemPrompt) {
    if (isMockMode || _model == null) return;

    // Preserve history? No, usually a context switch implies a new chat or we append it.
    // But for this use case, we probably want to restart the chat with new system prompt
    // but maybe keep history? Gemini API makes it hard to change system prompt mid-chat
    // without restarting.
    // Let's restart the chat session but we could potentially manually replay history if needed.
    // For now, simpler to just restart the session with new prompt.

    _chat = _model!.startChat(history: [Content.text(systemPrompt)]);
    // Note: We are NOT clearing _conversationHistory here so the UI still shows old messages,
    // but the AI's internal context is reset.
    // If that's confusing, we might want to clear history too.
    // Let's keep UI history but reset AI memory to avoid token limit and conflicts.
  }

  /// Dispose resources
  void dispose() {
    _chat = null;
    _model = null;
    _conversationHistory.clear();
  }
}
