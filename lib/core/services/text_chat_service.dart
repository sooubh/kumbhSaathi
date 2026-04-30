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

  // Use dynamically discovered model
  static String get _modelName => AIConfig.bestTextModel;

  String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/${AIConfig.bestTextModel}:generateContent?key=${AIConfig.apiKey}';

  bool _isRequestInProgress = false;
  final List<Completer<ConversationMessage>> _queue = [];
  Timer? _busyTimeout;

  /// Send a text message and get AI response with retry and optimization
  Future<ConversationMessage> sendMessage(
    String userMessage, {
    dynamic userProfile,
    dynamic location,
    String? appLanguage,
  }) async {
    // 1. Optimization: Avoid empty messages
    if (userMessage.trim().isEmpty) {
      throw 'Empty message';
    }

    // 2. Mock mode if API key is missing
    if (AIConfig.useMockMode) {
      _logger.i('🛠️ Mock Mode: Responding with simulated AI response');
      await Future.delayed(const Duration(seconds: 1));
      
      final mockText = userMessage.toLowerCase().contains('hello') 
          ? 'नमस्ते! I am Seva AI, your Kumbh Mela assistant. How can I help you today?' 
          : 'I am currently in demo mode, but I can help you with ghat locations, lost person reports, and emergency help.';
      
      final assistantMsg = ConversationMessage.assistant('[en] $mockText');
      
      // History addition is handled by logic after the mock return if I chose to continue, 
      // but let's just return here for mock.
      _conversationHistory.add(ConversationMessage.user(userMessage));
      _conversationHistory.add(assistantMsg);
      
      return assistantMsg;
    }

    // 3. Request Queuing: Ensure only one active AI request at a time
    if (_isRequestInProgress) {
      _logger.d('⏳ Request already in progress. Queuing message: ${userMessage.substring(0, 10)}...');
      final completer = Completer<ConversationMessage>();
      
      _queue.add(completer);
      
      // Safety: If the queue grows too large, clear it to avoid memory leaks
      if (_queue.length > 5) {
        _logger.w('⚠️ Queue too large, clearing oldest request.');
        final oldest = _queue.removeAt(0);
        if (!oldest.isCompleted) oldest.completeError('Queue full');
      }

      return completer.future.then((_) => sendMessage(
        userMessage, 
        userProfile: userProfile, 
        location: location, 
        appLanguage: appLanguage
      ));
    }

    _isRequestInProgress = true;
    
    // 3. Safety Timeout: Ensure lock is ALWAYS released eventually (max 60s)
    _busyTimeout?.cancel();
    _busyTimeout = Timer(const Duration(seconds: 60), () {
      if (_isRequestInProgress) {
        _logger.e('🚨 Request lock timed out after 60s! Forcibly clearing busy state.');
        _cleanupRequest();
      }
    });

    final startTime = DateTime.now();

    try {
      // Add user message to history
      final userMsg = ConversationMessage.user(userMessage);
      _conversationHistory.add(userMsg);

      // Build request body
      final requestBody = _buildRequestBody(
        userMessage,
        userProfile: userProfile,
        location: location,
        appLanguage: appLanguage,
      );

      // 4. Robust Retry Mechanism (Adaptive for 429)
      http.Response? response;
      int retryCount = 0;
      const int maxRetries = 2; // Reduced from 3 to avoid hammering

      while (retryCount <= maxRetries) {
        _logger.d('📤 Sending message to Gemini (Attempt ${retryCount + 1})');
        
        try {
          response = await http
              .post(
                Uri.parse(_apiUrl),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(requestBody),
              )
              .timeout(const Duration(seconds: 25));

          // Success!
          if (response.statusCode == 200) break;

          // Detect Rate Limit
          if (response.statusCode == 429) {
            final delay = _getRetryDelayFromResponse(response);
            _logger.w('⚠️ Rate limit hit (429). Server suggested delay: ${delay?.inSeconds ?? "none"}s');
            
            if (retryCount == maxRetries) break;

            // Wait before retry
            final waitDuration = delay ?? Duration(seconds: retryCount == 0 ? 1 : 2);
            _logger.i('🔄 Waiting ${waitDuration.inSeconds}s before retry #${retryCount + 1}...');
            await Future.delayed(waitDuration);
            
            retryCount++;
            continue;
          }

          // Other non-retryable errors
          _logger.e('❌ API Error: ${response.statusCode}');
          break;
        } catch (e) {
          _logger.w('⚠️ Connection error on attempt ${retryCount + 1}: $e');
          if (retryCount == maxRetries) rethrow;
          
          await Future.delayed(Duration(seconds: 1)); // small fixed delay for network issues
          retryCount++;
        }
      }

      if (response != null && response.statusCode == 200) {
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        
        final data = jsonDecode(response.body);
        final aiResponse = _parseResponse(data);

        // Add AI response to history
        final assistantMsg = ConversationMessage.assistant(aiResponse);
        _conversationHistory.add(assistantMsg);

        _logger.i('✅ Received response in ${duration}ms (Retries: $retryCount)');
        return assistantMsg;
      } else {
        final status = response?.statusCode ?? 'Unknown';
        if (status == 429) {
          _logger.e('❌ Quota exhausted (429) after $retryCount retries.');
          throw 'AI is temporarily rate-limited (Quota exhausted). Please try again after a short delay.';
        }
        
        final body = response?.body ?? 'No body';
        _logger.e('❌ All attempts failed: $status - $body');
        throw 'Failed to get response (Status: $status).';
      }
    } catch (e) {
      _logger.e('❌ TextChatService Exception: $e');
      rethrow;
    } finally {
      _cleanupRequest();
    }
  }

  /// Extracts retry delay from 429 response if available
  Duration? _getRetryDelayFromResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      final details = json['error']?['details'] as List?;
      if (details == null) return null;

      for (final detail in details) {
        if (detail['@type']?.contains('RetryInfo') == true) {
          final delayStr = detail['retryDelay'] as String?;
          if (delayStr != null) {
            // "52s" -> 52
            final seconds = int.tryParse(delayStr.replaceAll('s', ''));
            if (seconds != null) return Duration(seconds: seconds + 1); // add 1s buffer
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to parse retry delay: $e');
    }
    return null;
  }

  void _cleanupRequest() {
    _isRequestInProgress = false;
    _busyTimeout?.cancel();
    _busyTimeout = null;

    // Process next in queue if any
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      if (!next.isCompleted) next.complete();
    }
  }

  /// Build request body for Gemini API
  Map<String, dynamic> _buildRequestBody(
    String userMessage, {
    dynamic userProfile,
    dynamic location,
    String? appLanguage,
  }) {
    // Get system prompt with context
    final systemPrompt = AIConfig.getSystemPrompt(
      userProfile: userProfile,
      location: location,
      appLanguage: appLanguage,
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
