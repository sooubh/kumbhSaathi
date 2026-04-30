import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/ai_config.dart';

/// Service to handle Real-time interaction with Gemini Multimodal Live API
/// Uses WebSocket for bidirectional communication (Audio Streaming).
///
/// Protocol reference (from Python SDK + official docs):
///   1. Connect to WS endpoint
///   2. Send a `setup` message with model + generationConfig + systemInstruction
///   3. Wait for `setupComplete`
///   4. Stream audio via `realtime_input.media_chunks` at 16 kHz PCM
///   5. Receive audio at 24 kHz PCM via serverContent.modelTurn.parts[].inlineData
class RealtimeChatService {
  final _logger = Logger();
  static String get _liveModel => AIConfig.bestLiveModel;

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

  // Stream fired when Gemini interrupts itself (user spoke over the assistant)
  final _interruptedController = StreamController<void>.broadcast();
  Stream<void> get interruptedStream => _interruptedController.stream;

  // Stream for protocol/runtime errors surfaced to UI/provider
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  // Stream for socket lifecycle (true=connected, false=disconnected)
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final _setupCompleteController = StreamController<void>.broadcast();
  Stream<void> get setupCompleteStream => _setupCompleteController.stream;
  Completer<void>? _setupCompleter;

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

    if (AIConfig.apiKey.isEmpty) {
      throw Exception('Gemini API key is missing. Please configure GEMINI_API_KEY in .env');
    }

    try {
      final wsUrl = AIConfig.wsUrl;
      _logger.d('🔌 Connecting to Gemini Realtime: $wsUrl');
      _logger.d('🤖 Model: $_liveModel');

      // 1. Establish WebSocket Connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _connectionController.add(true);
      _setupCompleter = Completer<void>();

      // 2. Listen for messages
      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _logger.e('❌ WebSocket Error: $error');
          _failSetupIfPending('Realtime connection error: $error');
          disconnect(errorMessage: 'Realtime connection error: $error');
        },
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          _logger.d('🔌 WebSocket Connection Closed (code=$closeCode, reason=$closeReason)');
          _failSetupIfPending(
            'Realtime setup failed (code: ${closeCode ?? 'unknown'}): ${closeReason ?? 'Connection closed'}',
          );
          disconnect(
            errorMessage:
                'Realtime connection closed (code: ${closeCode ?? 'unknown'}): ${closeReason ?? 'Please retry'}',
          );
        },
      );

      // 3. Send Setup Message (Configuration)
      _sendSetupMessage(
        userProfile: userProfile,
        location: location,
        appLanguage: appLanguage,
        responseModalities: responseModalities,
      );

      // 4. Wait for setupComplete before streaming audio.
      await _setupCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Timed out waiting for setupComplete from Live API.');
        },
      );
    } catch (e) {
      _logger.e('❌ Connection Failed: $e');
      _isConnected = false;
      _connectionController.add(false);
      _setupCompleter = null;
      rethrow;
    }
  }

  void _failSetupIfPending(String message) {
    if (_setupCompleter != null && !_setupCompleter!.isCompleted) {
      _setupCompleter!.completeError(Exception(message));
    }
    _setupCompleter = null;
  }

  /// Disconnect and cleanup
  void disconnect({String? errorMessage}) {
    final wasConnected = _isConnected;

    _isConnected = false;
    _failSetupIfPending(errorMessage ?? 'Disconnected');
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;

    if (errorMessage != null && errorMessage.isNotEmpty) {
      _errorController.add(errorMessage);
    }
    if (wasConnected) {
      _connectionController.add(false);
    }
  }

  /// Send user AUDIO chunk to the model
  /// Input must be 16 kHz, mono, 16-bit PCM (as per API spec)
  void sendAudioChunk(Uint8List audioData) {
    if (!_isConnected || _channel == null) return;
    final encoded = base64Encode(audioData);
    final message = {
      'realtime_input': {
        'media_chunks': [
          {'mime_type': AIConfig.inputMimeType, 'data': encoded}
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
              {'text': text}
            ],
          }
        ],
        'turn_complete': true,
      },
    };
    _channel!.sink.add(jsonEncode(message));
  }

  /// Internal: Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
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

      if (json.containsKey('setupComplete') || json.containsKey('setup_complete')) {
        _logger.d('✅ Live setup complete');
        _setupCompleteController.add(null);
        if (_setupCompleter != null && !_setupCompleter!.isCompleted) {
          _setupCompleter!.complete();
        }
        _setupCompleter = null;
        return;
      }

      // 1. Handle server content (support both camelCase and snake_case)
      final dynamic serverContent = json['serverContent'] ?? json['server_content'];
      if (serverContent != null) {

        final inputTranscriptionText =
            serverContent['inputTranscription']?['text'] as String?;
        if (inputTranscriptionText != null && inputTranscriptionText.trim().isNotEmpty) {
          _textController.add(inputTranscriptionText.trim());
        }

        final outputTranscriptionText =
            serverContent['outputTranscription']?['text'] as String?;
        if (outputTranscriptionText != null && outputTranscriptionText.trim().isNotEmpty) {
          _textController.add(outputTranscriptionText.trim());
        }

        // A. Model Turn
        final dynamic modelTurn =
            serverContent['modelTurn'] ?? serverContent['model_turn'];
        if (modelTurn != null) {
          final parts = (modelTurn['parts'] as List?) ?? const [];
          for (final part in parts) {
            // Handle Audio
            final dynamic inlineData = part['inlineData'] ?? part['inline_data'];
            if (inlineData != null) {
              final mimeType = inlineData['mimeType'] ?? inlineData['mime_type'];
              final dataBase64 = inlineData['data'];

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
        if ((serverContent['turnComplete'] ?? serverContent['turn_complete']) ==
            true) {
          _turnCompleteController.add(null);
        }

        // C. Interruption (User spoke while AI was speaking)
        if ((serverContent['interrupted'] ?? serverContent['is_interrupted']) ==
            true) {
          _logger.d('🛑 AI Interrupted');
          _interruptedController.add(null);
        }
      }
      // 2. Handle audio_content (direct binary audio)
      final dynamic audioContent = json['audio_content'] ?? json['audioContent'];
      if (audioContent != null) {
        final dataBase64 = audioContent['data'];
        if (dataBase64 != null) {
          final bytes = base64Decode(dataBase64);
          _audioController.add(bytes);
        }
      }

      // 3. Handle tool_call (Future Implementation)
      else if (json.containsKey('toolCall') || json.containsKey('tool_call')) {
        _logger.d('🛠️ Tool Call Received: ${json['toolCall'] ?? json['tool_call']}');
      }
      // 4. Handle error
      else if (json.containsKey('error')) {
        final error = json['error'];
        final message = error is Map ? '${error['message'] ?? 'Unknown server error'}' : '$error';
        _logger.e('❌ Server Error: $message');
        _failSetupIfPending(message);
        _errorController.add(message);
      }
    } catch (e) {
      _logger.e('⚠️ Error parsing message: $e');
      _failSetupIfPending('Failed to parse realtime response: $e');
      _errorController.add('Failed to parse realtime response: $e');
    }
  }

  /// Internal: Send setup message to configure the session
  ///
  /// Format matches the official Gemini Live API protocol (camelCase JSON):
  ///   setup.model
  ///   setup.generationConfig.responseModalities
  ///   setup.generationConfig.speechConfig (with voice)
  ///   setup.systemInstruction
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

    // Matches the working Python reference configuration exactly
    final setup = {
      'setup': {
        'model': _liveModel,
        'generationConfig': {
          'responseModalities': responseModalities,
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': AIConfig.voiceName,
              },
            },
          },
        },
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      },
    };

    _channel!.sink.add(jsonEncode(setup));
    _logger.d('⚙️ Setup message sent (Model: $_liveModel, Modalities: $responseModalities, Voice: ${AIConfig.voiceName})');
  }
}
