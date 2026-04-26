import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import '../config/ai_config.dart';

/// Service to handle interactions with Google's Gemini AI
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  final Logger _logger = Logger();
  GenerativeModel? _model;
  ChatSession? _chatSession;

  /// Initialize the Gemini model
  void initialize() {
    try {
      _model = GenerativeModel(
        model: AIConfig.bestTextModel,
        apiKey: AIConfig.apiKey,
      );
      _logger.i('GeminiService initialized');
    } catch (e) {
      _logger.e('Error initializing GeminiService: $e');
    }
  }

  /// Start a new chat session
  void startChat() {
    if (_model == null) initialize();
    _chatSession = _model?.startChat(
      history: [
        Content.text(
          'You are KumbhSaathi, a helpful AI assistant for the Nashik Kumbh Mela. '
          'Keep your responses concise, helpful, and friendly. '
          'Provide information about ghats, sadhus, events, and navigation. '
          'If you do not know something, politely say so.',
        ),
      ],
    );
    _logger.i('New chat session started');
  }

  final TextChatService _textChatService = TextChatService();

  /// Send a message to Gemini and get a response
  Future<String> sendMessage(String message) async {
    try {
      final response = await _textChatService.sendMessage(message);
      return response.content;
    } catch (e) {
      _logger.e('Error sending message to Gemini: $e');
      if (e.toString().contains('429')) {
        return "The assistant is very busy right now. Please try again in a few seconds.";
      }
      return "I'm having trouble connecting to the network right now.";
    }
  }
}
