import 'gemini_live_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service that orchestrates Gemini Native Audio (Live API)
class VoiceAIService {
  final GeminiLiveService _liveService;

  bool _isInitialized = false;

  // Expose status stream
  Stream<String> get statusStream => _liveService.statusStream;
  bool get isConnected => _liveService.isConnected;

  VoiceAIService() : _liveService = GeminiLiveService();

  /// Initialize
  Future<bool> initialize() async {
    try {
      await _liveService.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      print('❌ VoiceAIService Init Failed: $e');
      return false;
    }
  }

  /// Check permissions
  Future<bool> checkPermissions() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Start Live Session
  Future<void> startSession(String systemPrompt) async {
    if (!_isInitialized) await initialize();

    final hasPerm = await checkPermissions();
    if (!hasPerm) {
      throw 'Microphone permission denied';
    }

    await _liveService.connect(systemPrompt);
    await _liveService.startStreaming();
  }

  /// Stop Session
  Future<void> endSession() async {
    await _liveService.stopStreaming();
    _liveService.dispose();
    // Re-initialize for next use if needed, or handle in dispose
  }

  /// Toggle Mic Mute (if implementing push-to-talk inside live)
  Future<void> setMicMuted(bool times) async {
    if (times) {
      await _liveService.stopStreaming();
    } else {
      await _liveService.startStreaming();
    }
  }

  void dispose() {
    _liveService.dispose();
  }

  // Legacy/Mock compatibility (if needed for rest of app, otherwise remove)
  // For now, we will stub or minimal
  bool get isMockMode => false;
}
