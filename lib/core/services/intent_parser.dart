import 'dart:convert';
import 'package:logger/logger.dart';
import '../../data/models/ai_intent.dart';

/// Parser for extracting intents and structured data from AI responses
class IntentParser {
  final _logger = Logger();

  /// Parse AI response text to extract intent
  AIIntent? parseIntent(String responseText) {
    try {
      // Try to find JSON in the response
      final jsonMatch = _extractJson(responseText);

      if (jsonMatch != null) {
        final jsonData = json.decode(jsonMatch) as Map<String, dynamic>;
        return AIIntent.fromJson(jsonData);
      }

      // If no JSON found, analyze text for intent
      return _analyzeTextForIntent(responseText);
    } catch (e) {
      _logger.e('❌ IntentParser: Failed to parse intent - $e');
      return null;
    }
  }

  /// Extract JSON from text (handles cases where AI adds explanation before/after JSON)
  String? _extractJson(String text) {
    // Look for JSON object in the text
    final jsonPattern = RegExp(
      r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
      multiLine: true,
      dotAll: true,
    );
    final matches = jsonPattern.allMatches(text);

    for (final match in matches) {
      final jsonStr = match.group(0);
      if (jsonStr != null && _isValidJson(jsonStr)) {
        return jsonStr;
      }
    }

    return null;
  }

  /// Check if string is valid JSON
  bool _isValidJson(String str) {
    try {
      json.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Analyze text to infer intent when no JSON is provided
  AIIntent? _analyzeTextForIntent(String text) {
    final lowerText = text.toLowerCase();

    // Check for various intent patterns
    if (_isNavigationIntent(lowerText)) {
      return AIIntent(
        type: IntentType.navigation,
        confidence: 0.7,
        data: {'location': _extractLocation(text)},
      );
    }

    if (_isSOSIntent(lowerText)) {
      return AIIntent(type: IntentType.sos, confidence: 0.9, data: {});
    }

    if (_isFacilitySearchIntent(lowerText)) {
      return AIIntent(
        type: IntentType.findFacility,
        confidence: 0.75,
        data: {'facilityType': _extractFacilityType(text)},
      );
    }

    // No specific intent detected - general query
    return AIIntent(type: IntentType.generalQuery, confidence: 0.5, data: {});
  }

  bool _isNavigationIntent(String text) {
    return text.contains('navigate') ||
        text.contains('take me') ||
        text.contains('go to') ||
        text.contains('direction') ||
        text.contains('how to reach');
  }

  bool _isSOSIntent(String text) {
    return text.contains('emergency') ||
        text.contains('urgent') ||
        text.contains('help immediately') ||
        text.contains('sos');
  }

  bool _isFacilitySearchIntent(String text) {
    return text.contains('find') ||
        text.contains('locate') ||
        text.contains('nearest') ||
        text.contains('where is');
  }

  String _extractLocation(String text) {
    // Simple extraction - look for proper nouns
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty && words[i][0] == words[i][0].toUpperCase()) {
        return words[i];
      }
    }
    return '';
  }

  String _extractFacilityType(String text) {
    if (text.toLowerCase().contains('medical') ||
        text.toLowerCase().contains('hospital')) {
      return 'medical';
    }
    if (text.toLowerCase().contains('police')) {
      return 'police';
    }
    if (text.toLowerCase().contains('toilet') ||
        text.toLowerCase().contains('washroom')) {
      return 'toilet';
    }
    if (text.toLowerCase().contains('ghat')) {
      return 'ghat';
    }
    return 'general';
  }

  /// Validate if all required fields are present for an intent
  bool validateIntent(AIIntent intent) {
    switch (intent.type) {
      case IntentType.reportLostPerson:
        return _validateLostPersonIntent(intent);
      case IntentType.navigation:
        return intent.data.containsKey('location') &&
            (intent.data['location'] as String).isNotEmpty;
      case IntentType.findFacility:
        return intent.data.containsKey('facilityType');
      case IntentType.sos:
        return true; // SOS doesn't require specific data
      case IntentType.generalQuery:
        return true;
    }
  }

  bool _validateLostPersonIntent(AIIntent intent) {
    final requiredFields = ['name', 'age', 'lastSeenLocation', 'guardianName'];
    return requiredFields.every(
      (field) =>
          intent.data.containsKey(field) &&
          intent.data[field] != null &&
          intent.data[field].toString().isNotEmpty,
    );
  }
}
