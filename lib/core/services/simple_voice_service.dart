import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';
import '../config/ai_config.dart';

/// Simple Voice AI Service using Gemini Native Audio
class SimpleVoiceService {
  WebSocketChannel? _socket;
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _logger = Logger();

  bool _isConnected = false;
  bool _isRecording = false;

  // Stream controller for status updates
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;

  /// Connect to Gemini Live API
  Future<void> connect(String systemPrompt) async {
    if (_isConnected) return;

    try {
      // Validate API key
      if (AIConfig.apiKey.isEmpty) {
        throw 'API key not configured';
      }

      final url = AIConfig.wsUrl;
      _logger.d('🔌 Connecting to Gemini Live API');

      _socket = WebSocketChannel.connect(Uri.parse(url));

      await _socket!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'Connection timeout',
      );

      _isConnected = true;
      _statusController.add('connected');
      _logger.i('✅ Connected to Gemini Live API');

      // Listen to responses
      _socket!.stream.listen(
        _onMessage,
        onError: (error) {
          _logger.e('❌ WebSocket error: $error');
          _disconnect();
        },
        onDone: () {
          _logger.w('WebSocket closed');
          _disconnect();
        },
      );

      // Send setup message
      _sendSetup(systemPrompt);
    } catch (e) {
      _logger.e('Connection failed: $e');
      _disconnect();
      throw 'Failed to connect: $e';
    }
  }

  /// Send setup configuration
  void _sendSetup(String systemPrompt) {
    final setupMsg = {
      "setup": {
        "model": AIConfig.modelName,
        "system_instruction": {
          "parts": [
            {"text": systemPrompt},
          ],
        },
        "generation_config": {
          "response_modalities": ["AUDIO"],
          "audio_config": {"voice": "en-IN", "audio_encoding": "LINEAR16"},
        },
      },
    };

    _socket?.sink.add(jsonEncode(setupMsg));
    _logger.d('📤 Setup sent');
  }

  /// Send greeting message
  void sendGreeting(String userName) {
    if (!_isConnected) return;

    final greetingMsg = {
      "client_content": {
        "turns": [
          {
            "role": "user",
            "parts": [
              {
                "text":
                    "Please greet $userName warmly and introduce yourself as their Kumbh Mela assistant. Keep it brief.",
              },
            ],
          },
        ],
        "turn_complete": true,
      },
    };

    _socket?.sink.add(jsonEncode(greetingMsg));
    _logger.d('📤 Greeting sent');
  }

  /// Start recording and streaming audio
  Future<void> startRecording() async {
    if (_isRecording || !_isConnected) return;

    try {
      // Check permission
      if (!await _recorder.hasPermission()) {
        throw 'Microphone permission denied';
      }

      _isRecording = true;
      _statusController.add('listening');
      _logger.i('🎙️ Started recording');

      // Start streaming
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      int silentFrames = 0;

      // Send audio chunks to Gemini
      stream.listen((Uint8List audioData) {
        if (_isConnected && audioData.isNotEmpty) {
          // Check for silence (simple zero check)
          // Note: Real silence might not be exactly 0, but for digital silence or mute it works.
          // For a robust VAD, checking amplitude threshold is better.
          // Here we check if all bytes are 0 or very close to 0.
          bool isSilent = audioData.every((b) => b == 0);

          if (isSilent) {
            silentFrames++;
          } else {
            silentFrames = 0;
          }

          // ~1 second of silence (approx 15-20 frames depending on chunk size)
          if (silentFrames > 15) {
            stopRecording(); // 🔥 Auto-stop and send turn_complete
            _logger.d('🤫 Silence detected, auto-stopping');
            return;
          }

          _sendAudio(audioData);
        }
      });
    } catch (e) {
      _logger.e('Failed to start recording: $e');
      _isRecording = false;
      throw 'Microphone error: $e';
    }
  }

  /// Send audio data to Gemini
  void _sendAudio(Uint8List audioData) {
    final msg = {
      "realtime_input": {
        "media_chunks": [
          {"mime_type": "audio/pcm", "data": base64Encode(audioData)},
        ],
      },
    };

    _socket?.sink.add(jsonEncode(msg));
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    await _recorder.stop();
    _isRecording = false;
    _logger.i('🛑 Stopped recording');

    // Signal turn complete to Gemini
    _socket?.sink.add(
      jsonEncode({
        "realtime_input": {"turn_complete": true},
      }),
    );
  }

  /// Handle incoming messages from Gemini
  Future<void> _onMessage(dynamic message) async {
    if (message is! String) return;

    try {
      final data = jsonDecode(message);

      // Handle server content
      if (data.containsKey('serverContent')) {
        final content = data['serverContent'];

        // Model is speaking
        if (content.containsKey('modelTurn')) {
          final modelTurn = content['modelTurn'];
          if (modelTurn['parts'] != null) {
            for (var part in modelTurn['parts']) {
              if (part.containsKey('inlineData')) {
                final mimeType = part['inlineData']['mime_type'];
                final base64Data = part['inlineData']['data'];

                if (mimeType.startsWith('audio/')) {
                  _statusController.add('speaking');
                  // STOP mic to prevent echo (Fix #3)
                  if (await _recorder.isRecording()) {
                    await stopRecording();
                  }
                  _playAudio(base64Data);
                }
              }
            }
          }
        }

        // Turn complete - back to listening
        if (content['turnComplete'] == true) {
          _statusController.add('listening');
          // Resume mic
          // if (await _recorder.isPaused()) {
          //   await _recorder.resume();
          // }
          // NOTE: We don't auto-resume. User must tap to speak again (Half-Duplex).
        }

        // Interrupted
        if (content.containsKey('interrupted')) {
          _statusController.add('interrupted');
          _player.stop();
        }
      }
    } catch (e) {
      _logger.e('Error handling message: $e');
    }
  }

  /// Play audio response
  Future<void> _playAudio(String base64Audio) async {
    try {
      final audioBytes = base64Decode(base64Audio);

      // Stop previous audio to prevent overlap
      await _player.stop();

      // Play using BytesSource
      await _player.play(BytesSource(audioBytes));

      _logger.d('🔊 Playing audio');
    } catch (e) {
      _logger.e('Failed to play audio: $e');
      _statusController.add('listening');
    }
  }

  /// Disconnect
  void disconnect() {
    _disconnect();
  }

  void _disconnect() {
    _isConnected = false;
    _isRecording = false;

    _recorder.stop();
    _player.stop();
    _socket?.sink.close();
    _socket = null;

    _statusController.add('disconnected');
    _logger.i('🔌 Disconnected');
  }

  /// Dispose resources
  void dispose() {
    _disconnect();
    _recorder.dispose();
    _player.dispose();
    _statusController.close();
  }
}
