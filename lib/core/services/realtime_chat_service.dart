import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/ai_config.dart';

/// Service to handle Real-time interaction with Gemini Multimodal Live API
/// Uses WebSocket for bidirectional communication
class RealtimeChatService {
  final _logger = Logger();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Stream controller to expose AI responses to the UI/Provider
  final _responseController = StreamController<String>.broadcast();
  Stream<String> get responseStream => _responseController.stream;

  // Stream for turn completion events
  final _turnCompleteController = StreamController<void>.broadcast();
  Stream<void> get turnCompleteStream => _turnCompleteController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Connect to the Gemini Realtime WebSocket
  Future<void> connect({
    dynamic userProfile,
    dynamic location,
    String? appLanguage,
  }) async {
    if (_isConnected) return;

    try {
      final wsUrl = AIConfig.wsUrl;
      _logger.d('🔌 Connecting to Gemini Realtime: $wsUrl');

      // 1. Establish WebSocket Connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      // 2. Listen for messages
      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _logger.e('❌ WebSocket Error: $error');
          _responseController.addError(error);
          disconnect();
        },
        onDone: () {
          _logger.d('🔌 WebSocket Connection Closed');
          disconnect();
        },
      );

      // 3. Send Setup Message (Configuration)
      _sendSetupMessage(
        userProfile: userProfile,
        location: location,
        appLanguage: appLanguage,
      );
    } catch (e) {
      _logger.e('❌ Connection Failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Disconnect and cleanup
  void disconnect() {
    _isConnected = false;
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
  }

  /// Send user text input to the model
  void sendTextMessage(String text) {
    if (!_isConnected || _channel == null) {
      _logger.w('⚠️ Cannot send message: Not connected');
      return;
    }

    final message = {
      'client_content': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turn_complete': true,
      },
    };

    _channel!.sink.add(jsonEncode(message));
    _logger.d('📤 Sent: $text');
  }

  /// Internal: Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      // Parse as Map explicitly
      final Map<String, dynamic> json = data is String
          ? jsonDecode(data)
          : data as Map<String, dynamic>;

      // 1. Handle server_content (Model turns, interruptions, turn complete)
      if (json.containsKey('serverContent')) {
        final serverContent = json['serverContent'];

        // A. Model Turn (Text Generation)
        if (serverContent.containsKey('modelTurn')) {
          final parts = serverContent['modelTurn']['parts'] as List;
          for (final part in parts) {
            if (part.containsKey('text')) {
              final text = part['text'] as String;
              if (text.isNotEmpty) {
                _responseController.add(text);
              }
            }
          }
        }

        // B. Turn Complete
        if (serverContent.containsKey('turnComplete')) {
          // Logic for end of turn (e.g. stop loading indicator)
          _logger.d('🤖 Turn Complete');
        }
      }
      // 2. Handle tool_call (Future Implementation)
      else if (json.containsKey('toolCall')) {
        _logger.d('🛠️ Tool Call Received: ${json['toolCall']}');
      }
      // 3. Handle error
      else if (json.containsKey('error')) {
        // Usually valid JSON error structure
        final error = json['error'];
        _logger.e('❌ Server Error: ${error['message']}');
        _responseController.addError(
          error['message'] ?? 'Unknown Server Error',
        );
      }
    } catch (e) {
      _logger.e('⚠️ Error parsing message: $e\nData: $data');
    }
  }

  /// Internal: Send setup message to configure the session
  void _sendSetupMessage({
    dynamic userProfile,
    dynamic location,
    String? appLanguage,
  }) {
    if (_channel == null) return;

    final systemPrompt = AIConfig.getSystemPrompt(
      userProfile: userProfile,
      location: location,
      appLanguage: appLanguage,
    );

    final setup = {
      'setup': {
        'model':
            'models/gemini-2.0-flash-exp', // Or 'models/gemini-pro' depending on availability
        'generation_config': {
          'response_modalities': [
            'TEXT',
          ], // We only want TEXT back for now to feed TTS
          'speech_config': {
            'voice_config': {
              'prebuilt_voice_config': {
                'voice_name': 'Aoede',
              }, // Optional voice config
            },
          },
        },
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      },
    };

    _channel!.sink.add(jsonEncode(setup));
    _logger.d('⚙️ Setup message sent');
  }
}
