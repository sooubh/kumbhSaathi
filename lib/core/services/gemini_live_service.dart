import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/ai_config.dart';

/// Service for interacting with Gemini Multimodal Live API (WebSocket)
class GeminiLiveService {
  WebSocketChannel? _channel;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final Logger _logger = Logger();

  bool _isConnected = false;
  bool _isRecording = false;

  // Stream controller for exposing status updates to UI
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  StreamSubscription<Uint8List>? _audioSubscription;
  final StreamController<Uint8List> _recordingDataController =
      StreamController<Uint8List>();

  bool get isConnected => _isConnected;

  /// Initialize Audio Streams
  Future<void> initialize() async {
    await _recorder.openRecorder();
    await _player.openPlayer();

    // Set Log Level
    _player.setLogLevel(Level.warning);
    _recorder.setLogLevel(Level.warning);

    _logger.i('✅ GeminiLiveService: Audio streams init (flutter_sound)');
  }

  /// Connect to Gemini WebSocket
  Future<void> connect(String systemInstruction) async {
    if (_isConnected) return;

    try {
      final url = AIConfig.wsUrl;
      _logger.d('CONNECTING TO: $url');
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _isConnected = true;
      _statusController.add('connected');

      // Listen to incoming messages (Audio/Json)
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _logger.e('❌ WebSocket Error: $error');
          _disconnect();
        },
        onDone: () {
          _logger.w('❌ WebSocket Closed');
          // _disconnect();
        },
      );

      // Send initial setup message
      _sendSetup(systemInstruction);

      // Start Playing Stream
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 24000,
        bufferSize: 8192,
        interleaved: false,
      );
    } catch (e) {
      _logger.e('❌ Connection Failed: $e');
      _disconnect();
      rethrow;
    }
  }

  void _sendSetup(String systemInstruction) {
    final setupMsg = {
      "setup": {
        "model": "models/${AIConfig.modelName}",
        "generation_config": {
          "response_modalities": ["AUDIO"],
          "speech_config": {
            "voice_config": {
              "prebuilt_voice_config": {"voice_name": "Puck"},
            },
          },
        },
        "system_instruction": {
          "parts": [
            {"text": systemInstruction},
          ],
        },
      },
    };
    _channel?.sink.add(jsonEncode(setupMsg));
    _logger.d('📤 Sent Setup Message');
  }

  /// Start bidirectional audio streaming
  Future<void> startStreaming() async {
    if (!_isConnected || _isRecording) return;

    // Ensure permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    _isRecording = true;
    _statusController.add('listening');

    // Start Recorder to Stream
    await _recorder.startRecorder(
      toStream: _recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );

    // Listen to the controller's stream
    _audioSubscription = _recordingDataController.stream.listen((data) {
      if (_isConnected && data.isNotEmpty) {
        _sendAudioChunk(data);
      }
    });

    _logger.i('🎙️ Mic Started');
  }

  void _sendAudioChunk(Uint8List data) {
    // Convert to base64
    final base64Audio = base64Encode(data);

    final msg = {
      "realtime_input": {
        "media_chunks": [
          {"mime_type": "audio/pcm", "data": base64Audio},
        ],
      },
    };

    _channel?.sink.add(jsonEncode(msg));
  }

  /// Stop mic recording
  Future<void> stopStreaming() async {
    if (_isRecording) {
      await _recorder.stopRecorder();
      _audioSubscription?.cancel();
      _isRecording = false;
      _logger.i('Mic Stopped');
    }
  }

  /// Handle incoming messages from Gemini
  void _handleMessage(dynamic message) {
    if (message is String) {
      try {
        final Map<String, dynamic> data = jsonDecode(message);

        // Handle ServerContent
        if (data.containsKey('serverContent')) {
          final content = data['serverContent'];

          // 1. Turn Interrupted
          if (content.containsKey('interrupted')) {
            _logger.w('⚡ Interrupted');

            _player.stopPlayer();
            _player.startPlayerFromStream(
              codec: Codec.pcm16,
              numChannels: 1,
              sampleRate: 24000,
              bufferSize: 8192,
              // ignore: unexpected_null_error
              interleaved: false,
            );
            _statusController.add('interrupted');
            return;
          }

          // 2. Model Turn (Audio Response)
          if (content.containsKey('modelTurn')) {
            final parts = content['modelTurn']['parts'] as List;
            for (var part in parts) {
              if (part.containsKey('inlineData')) {
                final mimeType = part['inlineData']['mime_type'];
                final base64Data = part['inlineData']['data'];

                if (mimeType.startsWith('audio/')) {
                  _statusController.add('speaking');
                  final audioBytes = base64Decode(base64Data);
                  _playAudio(audioBytes);
                }
              }
            }
          }
        }
      } catch (e) {
        _logger.e('Error parsing message: $e');
      }
    }
  }

  Future<void> _playAudio(Uint8List audioData) async {
    // Add to player buffer
    if (_player.isPlaying) {
      await _player.feedUint8FromStream(audioData);
    }
  }

  void _disconnect() {
    _isConnected = false;
    _isRecording = false;
    _channel?.sink.close();
    _channel = null;

    _recorder.stopRecorder();
    _player.stopPlayer();
    _audioSubscription?.cancel();

    _statusController.add('disconnected');
    _logger.i('🔌 Disconnected');
  }

  void dispose() {
    _disconnect();
    _recorder.closeRecorder();
    _player.closePlayer();
    _statusController.close();
    _recordingDataController.close();
  }
}
