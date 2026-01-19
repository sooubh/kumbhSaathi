import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

/// Service to handle Text-to-Speech (TTS)
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();

  bool _isInitialized = false;

  /// Initialize TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // await _flutterTts.setLanguage("en-IN"); // specific language handling moved to setLanguage
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);

      // Log available voices for debugging
      final voices = await _flutterTts.getVoices;
      _logger.d('Available Voices: $voices');

      // Handle completion
      _flutterTts.setCompletionHandler(() {
        _logger.d('TTS Finished');
      });

      _isInitialized = true;
      _logger.i('AudioService initialized');
    } catch (e) {
      _logger.e('Error initializing AudioService: $e');
    }
  }

  /// Set TTS language and best matching voice
  Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) await initialize();
    try {
      await _flutterTts.setLanguage(languageCode);

      // Try to find a voice that matches the language code specifically
      // This helps get the right accent (e.g., Indian English vs US English)
      final voices = await _flutterTts.getVoices;
      try {
        List<dynamic> availableVoices = voices as List<dynamic>;
        // Look for a voice name that contains the country code (IN)
        final bestVoice = availableVoices.firstWhere(
          (v) =>
              v['locale'].toString().contains(languageCode) ||
              (v['name'].toString().toLowerCase().contains('india') &&
                  languageCode.contains('IN')),
          orElse: () => null,
        );

        if (bestVoice != null) {
          _logger.i('Setting specific voice: ${bestVoice['name']}');
          await _flutterTts.setVoice({
            "name": bestVoice["name"],
            "locale": bestVoice["locale"],
          });
        }
      } catch (e) {
        _logger.w('Could not set specific voice: $e');
      }

      _logger.d('TTS Language set to: $languageCode');
    } catch (e) {
      _logger.e('Error setting TTS language: $e');
    }
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      _logger.e('Error playing TTS: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      _logger.e('Error stopping TTS: $e');
    }
  }
}
