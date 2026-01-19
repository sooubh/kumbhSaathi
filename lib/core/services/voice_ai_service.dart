import 'dart:async';
import 'package:logger/logger.dart';
import 'simple_voice_service.dart';

/// Wrapper service for voice AI functionality
class VoiceAIService {
  final SimpleVoiceService _service = SimpleVoiceService();
  final _logger = Logger();

  bool _isInitialized = false;

  // Expose status stream
  Stream<String> get statusStream => _service.statusStream;
  bool get isConnected => _service.isConnected;

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      // No complex initialization needed anymore
      _isInitialized = true;
      _logger.i('✅ VoiceAIService initialized');
      return true;
    } catch (e) {
      _logger.e('❌ Init failed: $e');
      return false;
    }
  }

  /// Start voice session
  Future<void> startSession(String systemPrompt) async {
    if (!_isInitialized) await initialize();

    await _service.connect(systemPrompt);
    // Don't auto-start recording. Let the greeting play first.
    // User can tap mic to reply.
  }

  /// End voice session
  Future<void> endSession() async {
    await _service.stopRecording();
    _service.disconnect();
  }

  /// Send greeting
  void sendGreeting(String userName) {
    _service.sendGreeting(userName);
  }

  /// Dispose
  void dispose() {
    _service.dispose();
  }

  // Legacy compatibility
  bool get isMockMode => false;
}
