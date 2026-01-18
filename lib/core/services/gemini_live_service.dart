import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:collection';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import '../config/ai_config.dart';

/// Service for interacting with Gemini Multimodal Live API (WebSocket)
class GeminiLiveService {
  WebSocketChannel? _channel;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final Logger _logger = Logger();

  bool _isConnected = false;
  bool _isRecording = false;

  // Reconnection state
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  String? _lastSystemInstruction;

  // Stream subscription tracking
  StreamSubscription? _messageSubscription;

  // Health monitoring
  Timer? _heartbeatTimer;
  DateTime? _lastMessageReceived;
  static const Duration _heartbeatInterval = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 30);

  // Audio buffering
  final Queue<Uint8List> _audioSendBuffer = Queue();
  final Queue<Uint8List> _audioReceiveBuffer = Queue();
  Timer? _sendBufferProcessor;
  Timer? _playBufferProcessor;
  static const Duration _bufferInterval = Duration(milliseconds: 50);

  // Stream controller for exposing status updates to UI
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Helper to safely add status without errors
  void _safeAddStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Uint8List _pcmRemainder = Uint8List(0); // For handling odd-byte chunks

  StreamSubscription<Uint8List>? _audioSubscription;
  final StreamController<Uint8List> _recordingDataController =
      StreamController<Uint8List>();

  bool get isConnected => _isConnected;

  /// Initialize Audio Streams
  Future<void> initialize() async {
    // Configure Audio Session
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker |
            AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowAirPlay,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    await _recorder.openRecorder();
    await _player.openPlayer();

    _logger.i(
      '✅ GeminiLiveService: Audio streams init (flutter_sound + audio_session)',
    );
  }

  /// Connect to Gemini WebSocket
  Future<void> connect(String systemInstruction) async {
    if (_isConnected) return;

    try {
      final url = AIConfig.wsUrl;
      _logger.d('CONNECTING TO: $url');

      // Store for reconnection
      _lastSystemInstruction = systemInstruction;

      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Wait for WebSocket to be ready
      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('WebSocket connection timeout');
        },
      );

      _isConnected = true;
      _safeAddStatus('connected');
      _logger.i('✅ WebSocket Connected');

      // Cancel old subscription if exists
      _messageSubscription?.cancel();

      // Listen to incoming messages (Audio/Json)
      _messageSubscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _logger.e('❌ WebSocket Error: $error');
          _disconnect();
          _attemptReconnect();
        },
        onDone: () {
          _logger.w('❌ WebSocket Closed');
          _disconnect();
          _attemptReconnect();
        },
        cancelOnError: false,
      );

      // Send initial setup message
      _sendSetup(systemInstruction);

      // Start Playing Stream
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 24000,
        bufferSize: 16384,
        interleaved: true,
      );

      // Start health monitoring
      _startHealthMonitoring();

      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
    } catch (e) {
      _logger.e('❌ Connection Failed: $e');
      _disconnect();
      _attemptReconnect();
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

  /// Send initial greeting prompt
  void sendInitialGreeting(String userName) {
    if (!_isConnected) return;

    final greetingMsg = {
      "client_content": {
        "turns": [
          {
            "role": "user",
            "parts": [
              {
                "text":
                    "Please greet $userName warmly and introduce yourself as their Kumbh Mela assistant. Keep it brief and friendly.",
              },
            ],
          },
        ],
        "turn_complete": true,
      },
    };
    _channel?.sink.add(jsonEncode(greetingMsg));
    _logger.d('📤 Sent Greeting Request');
  }

  /// Attempt reconnection with exponential backoff
  Future<void> _attemptReconnect() async {
    if (_isReconnecting ||
        _reconnectAttempts >= _maxReconnectAttempts ||
        _lastSystemInstruction == null) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    _logger.w(
      '🔄 Attempting reconnection ($_reconnectAttempts/$_maxReconnectAttempts)',
    );
    _safeAddStatus('reconnecting');

    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      try {
        await connect(_lastSystemInstruction!);
        _isReconnecting = false;
        _safeAddStatus('reconnected');
        _logger.i('✅ Reconnected successfully');
      } catch (e) {
        _logger.e('❌ Reconnect failed: $e');
        _isReconnecting = false;
        await _attemptReconnect(); // Retry
      }
    });
  }

  /// Start connection health monitoring
  void _startHealthMonitoring() {
    _lastMessageReceived = DateTime.now();

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _checkConnectionHealth();
    });
  }

  /// Check connection health via heartbeat
  void _checkConnectionHealth() {
    if (_lastMessageReceived == null || !_isConnected) return;

    final timeSinceLastMessage = DateTime.now().difference(
      _lastMessageReceived!,
    );

    if (timeSinceLastMessage > _connectionTimeout) {
      _logger.w(
        '⚠️ Connection timeout (no messages for ${timeSinceLastMessage.inSeconds}s)',
      );
      _safeAddStatus('connection_timeout');
      _disconnect();
      _attemptReconnect();
    }
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
    _safeAddStatus('listening');

    // Start Recorder to Stream
    await _recorder.startRecorder(
      toStream: _recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000, // 🔥 Changed to 16kHz for better device compatibility
    );

    // Listen to the controller's stream
    _audioSubscription = _recordingDataController.stream.listen((data) {
      if (_isConnected && data.isNotEmpty) {
        // PCM16 safety: ensure even length
        if (data.length % 2 != 0) {
          data = data.sublist(0, data.length - 1);
        }
        if (data.isNotEmpty) {
          _sendAudioChunk(data);
        }
      }
    });

    _logger.i('🎙️ Mic Started');
  }

  void _sendAudioChunk(Uint8List data) {
    // Add to buffer instead of immediate send
    _audioSendBuffer.add(data);

    // Start buffer processor if not running
    if (_sendBufferProcessor == null || !_sendBufferProcessor!.isActive) {
      _sendBufferProcessor = Timer.periodic(_bufferInterval, (_) {
        _processSendBuffer();
      });
    }
  }

  /// Process send buffer in batches
  void _processSendBuffer() {
    if (_audioSendBuffer.isEmpty || !_isConnected) return;

    // Batch multiple chunks for efficiency (max 5 at a time)
    final batch = <Uint8List>[];
    while (_audioSendBuffer.isNotEmpty && batch.length < 5) {
      batch.add(_audioSendBuffer.removeFirst());
    }

    for (final chunk in batch) {
      final base64Audio = base64Encode(chunk);
      final msg = {
        "realtime_input": {
          "media_chunks": [
            {"mime_type": "audio/pcm", "data": base64Audio},
          ],
        },
      };
      _channel?.sink.add(jsonEncode(msg));
    }
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
  Future<void> _handleMessage(dynamic message) async {
    // Track message activity for health monitoring
    _lastMessageReceived = DateTime.now();

    if (message is String) {
      try {
        _logger.d('📥 Received: $message'); // Debug log
        final Map<String, dynamic> data = jsonDecode(message);

        // Handle ServerContent
        if (data.containsKey('serverContent')) {
          final content = data['serverContent'];

          // 1. Turn Interrupted
          if (content.containsKey('interrupted')) {
            _logger.w('⚡ Interrupted');
            await _player.stopPlayer();
            _pcmRemainder = Uint8List(0); // Clear buffer

            await _player.startPlayerFromStream(
              codec: Codec.pcm16,
              numChannels: 1,
              sampleRate: 24000,
              bufferSize: 16384,
              interleaved: true,
            );
            _safeAddStatus('interrupted');
            // Give UI a moment to show "Interrupted" then switch to "Listening"
            Future.delayed(const Duration(milliseconds: 500), () {
              _safeAddStatus('listening');
            });
            return;
          }

          // 2. Model Turn (Audio Response)
          if (content.containsKey('modelTurn')) {
            final modelTurn = content['modelTurn'];
            if (modelTurn['parts'] != null) {
              final parts = modelTurn['parts'] as List;
              for (var part in parts) {
                if (part.containsKey('inlineData')) {
                  final mimeType = part['inlineData']['mime_type'];
                  final base64Data = part['inlineData']['data'];

                  if (mimeType.startsWith('audio/')) {
                    _safeAddStatus('speaking');
                    final audioBytes = base64Decode(base64Data);
                    _playAudio(audioBytes);
                  }
                }
              }
            }
          }

          // 3. Turn Complete (Runs last to ensure 'listening' ignores previous 'speaking')
          if (content.containsKey('turnComplete') &&
              content['turnComplete'] == true) {
            _safeAddStatus('listening');
          }
        } else {
          _logger.w('⚠️ Unknown message format: ${data.keys.toList()}');
        }
      } catch (e) {
        _logger.e('Error parsing message: $e');
      }
    } else if (message is Uint8List) {
      // Handle binary PCM audio directly
      try {
        _safeAddStatus('speaking');
        _playAudio(message);
      } catch (e) {
        _logger.e('Error playing binary audio: $e');
      }
    } else {
      _logger.d('📥 Received Unknown Message Type: ${message.runtimeType}');
    }
  }

  Future<void> _playAudio(Uint8List newData) async {
    // Add to receive buffer
    _audioReceiveBuffer.add(newData);

    // Start buffer processor if not running
    if (_playBufferProcessor == null || !_playBufferProcessor!.isActive) {
      _playBufferProcessor = Timer.periodic(_bufferInterval, (_) {
        _processPlayBuffer();
      });
    }
  }

  /// Process play buffer
  Future<void> _processPlayBuffer() async {
    if (_audioReceiveBuffer.isEmpty) return;

    final data = _audioReceiveBuffer.removeFirst();

    try {
      // Merge remainder + new chunk
      final merged = Uint8List(_pcmRemainder.length + data.length);
      merged.setAll(0, _pcmRemainder);
      merged.setAll(_pcmRemainder.length, data);

      // PCM16 requires even length
      final evenLength = merged.length - (merged.length % 2);

      if (evenLength > 0) {
        final playable = merged.sublist(0, evenLength);
        await _player.feedUint8FromStream(playable);
      }

      // Save leftover byte (if any)
      _pcmRemainder = merged.sublist(evenLength);
    } catch (e) {
      _logger.e(
        '❌ PCM decoding error: malformed 16-bit audio stream (unaligned buffer)',
      );
    }
  }

  /// Disconnect without disposing resources (allows reconnection)
  void disconnect() {
    if (!_isConnected && !_isReconnecting) return;

    _isConnected = false;
    _isRecording = false;

    // Cancel all timers
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _sendBufferProcessor?.cancel();
    _sendBufferProcessor = null;
    _playBufferProcessor?.cancel();
    _playBufferProcessor = null;

    // Close WebSocket
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _channel?.sink.close();
    _channel = null;

    // Stop audio
    _recorder.stopRecorder();
    _player.stopPlayer();
    _audioSubscription?.cancel();

    // Clear buffers
    _audioSendBuffer.clear();
    _audioReceiveBuffer.clear();

    // Don't reset reconnection state here - let reconnection logic handle it

    _safeAddStatus('disconnected');
    _logger.i('🔌 Disconnected');
  }

  /// Internal disconnect for error handling
  void _disconnect() {
    disconnect();
  }

  void dispose() {
    // Disconnect first
    if (_isConnected) {
      disconnect();
    }

    // Close audio resources
    _recorder.closeRecorder();
    _player.closePlayer();

    // Close controllers only after disconnecting
    if (!_statusController.isClosed) {
      _statusController.close();
    }
    if (!_recordingDataController.isClosed) {
      _recordingDataController.close();
    }
  }
}
