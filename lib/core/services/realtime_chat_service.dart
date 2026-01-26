import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/ai_config.dart';

/// Service to handle Real-time interaction with Gemini Multimodal Live API
/// Uses WebSocket for bidirectional communication (Audio Streaming)
class RealtimeChatService {
  final _logger = Logger();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Stream controller to expose AI Audio chunks
  final _audioController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioStream => _audioController.stream;

  // Stream for text transcripts (optional, if model sends them)
  final _textController = StreamController<String>.broadcast();
  Stream<String> get textStream => _textController.stream;

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
    List<String> responseModalities = const ['AUDIO'],
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
          _isConnected = false;
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
        responseModalities: responseModalities,
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

  /// Send user AUDIO chunk to the model
  void sendAudioChunk(Uint8List audioData) {
    if (!_isConnected || _channel == null) return;

    final message = {
      'realtime_input': {
        'media_chunks': [
          {'mime_type': 'audio/pcm', 'data': base64Encode(audioData)},
        ],
      },
    };

    _channel!.sink.add(jsonEncode(message));
  }

  /// Send user text input to the model (if needed)
  void sendTextMessage(String text) {
    if (!_isConnected || _channel == null) return;

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
  }

  /// Internal: Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      _logger.d('📩 Message Type: ${data.runtimeType}');

      Map<String, dynamic> json;
      if (data is String) {
        json = jsonDecode(data);
      } else if (data is List<int> || data is Uint8List) {
        // Handle binary frame (likely UTF-8 encoded JSON)
        json = jsonDecode(utf8.decode(data as List<int>));
      } else {
        _logger.w('⚠️ Unknown message format: ${data.runtimeType}');
        return;
      }

      // 1. Handle server_content
      if (json.containsKey('serverContent')) {
        final serverContent = json['serverContent'];

        // A. Model Turn
        if (serverContent.containsKey('modelTurn')) {
          final parts = serverContent['modelTurn']['parts'] as List;
          for (final part in parts) {
            // Handle Audio
            if (part.containsKey('inlineData')) {
              final mimeType = part['inlineData']['mimeType'];
              final dataBase64 = part['inlineData']['data'];

              if (mimeType.toString().startsWith('audio/')) {
                final bytes = base64Decode(dataBase64);
                _audioController.add(bytes);
              }
            }
            // Handle Text (if enabled/received)
            else if (part.containsKey('text')) {
              final text = part['text'] as String;
              if (text.isNotEmpty) {
                _textController.add(text);
              }
            }
          }
        }

        // B. Turn Complete
        if (serverContent.containsKey('turnComplete')) {
          // Logic for end of turn (signal to flush buffer if needed)
          _turnCompleteController.add(null);
        }

        // C. Interruption (User spoke while AI was speaking)
        if (serverContent.containsKey('interrupted')) {
          _logger.d('🛑 AI Interrupted');
          // You might want to clear local audio buffers here
          // We will handle this in the provider
        }
      }
      // 2. Handle tool_call (Future Implementation)
      else if (json.containsKey('toolCall')) {
        _logger.d('🛠️ Tool Call Received: ${json['toolCall']}');
      }
      // 3. Handle error
      else if (json.containsKey('error')) {
        final error = json['error'];
        _logger.e('❌ Server Error: ${error['message']}');
      }
    } catch (e) {
      _logger.e('⚠️ Error parsing message: $e');
    }
  }

  /// Internal: Send setup message to configure the session
  void _sendSetupMessage({
    dynamic userProfile,
    dynamic location,
    String? appLanguage,
    List<String> responseModalities = const ['AUDIO'],
  }) {
    if (_channel == null) return;

    final systemPrompt = AIConfig.getSystemPrompt(
      userProfile: userProfile,
      location: location,
      appLanguage: appLanguage,
    );

    final setup = {
      'setup': {
        'model': 'models/gemini-2.0-flash-exp',
        'generation_config': {
          'response_modalities': responseModalities, // Dynamic modalities
          'speech_config': {
            'voice_config': {
              'prebuilt_voice_config': {
                'voice_name':
                    'Aoede', // 'Puck', 'Charon', 'Kore', 'Fenrir', 'Aoede'
              },
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
    _logger.d('⚙️ Setup message sent (Modalities: $responseModalities)');
  }
}
