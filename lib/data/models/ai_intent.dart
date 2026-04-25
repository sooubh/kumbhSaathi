/// Intent types that AI can recognize
enum IntentType {
  reportLostPerson,
  navigation,
  findFacility,
  sos,
  generalQuery,
}

/// AI-identified intent with extracted data
class AIIntent {
  final IntentType type;
  final Map<String, dynamic> data;
  final double confidence;
  final List<String> missingFields;
  final String? nextQuestion;

  const AIIntent({
    required this.type,
    required this.data,
    required this.confidence,
    this.missingFields = const [],
    this.nextQuestion,
  });

  bool get isComplete => missingFields.isEmpty;
  bool get isConfident => confidence >= 0.7;

  factory AIIntent.fromJson(Map<String, dynamic> json) {
    return AIIntent(
      type: _parseIntentType(json['intent'] as String),
      data: json['data'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      missingFields:
          (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nextQuestion: json['nextQuestion'] as String?,
    );
  }

  static IntentType _parseIntentType(String intent) {
    switch (intent) {
      case 'report_lost_person':
        return IntentType.reportLostPerson;
      case 'navigation':
        return IntentType.navigation;
      case 'find_facility':
        return IntentType.findFacility;
      case 'sos':
        return IntentType.sos;
      default:
        return IntentType.generalQuery;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': type.toString().split('.').last,
      'data': data,
      'confidence': confidence,
      'missingFields': missingFields,
      'nextQuestion': nextQuestion,
    };
  }
}
