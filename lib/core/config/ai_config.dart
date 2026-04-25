import 'env.dart';

/// AI Configuration for Gemini Integration
class AIConfig {
  // Model configuration
  static const String modelName = 'models/gemini-2.0-flash-exp';

  static String get apiKey {
    return Env.geminiApiKey;
  }

  static String get wsUrl {
    return 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey';
  }

  static bool get useMockMode => apiKey.isEmpty;

  // System prompt for the AI assistant
  static String getSystemPrompt({
    dynamic userProfile, // UserProfile?
    dynamic location, // Position?
    Map<String, dynamic>? crowdStats,
    String? appLanguage,
  }) {
    final name = userProfile?.name ?? 'Pilgrim';
    final age = userProfile?.age?.toString() ?? 'unknown';
    final gender = userProfile?.gender ?? 'unknown';

    String locationInfo = 'Unknown location';
    if (location != null) {
      locationInfo =
          'Lat: ${location.latitude}, Lng: ${location.longitude} (Accuracy: ${location.accuracy}m)';
    }

    final emergencyContacts =
        userProfile?.emergencyContacts != null &&
            (userProfile.emergencyContacts as List).isNotEmpty
        ? (userProfile.emergencyContacts as List)
              .map((c) => '${c.name} (${c.relation}): ${c.phone}')
              .join(', ')
        : 'None';

    String crowdInfo = 'Crowd data unavailable';
    if (crowdStats != null) {
      crowdInfo =
          'Total Ghats: ${crowdStats['totalGhats']}\n'
          'Low Crowd: ${crowdStats['lowCrowd']}\n'
          'Medium Crowd: ${crowdStats['mediumCrowd']}\n'
          'High Crowd: ${crowdStats['highCrowd']}';
    }

    return '''
You are an AI assistant for KumbhSaathi, helping users at the Nashik Kumbh Mela in India.

CURRENT USER CONTEXT:
- Name: $name
- Age: $age
- Gender: $gender
- Current Location: $locationInfo
- Emergency Contacts: $emergencyContacts
- App Language Preference: ${appLanguage ?? 'Not specified'}

LIVE CROWD STATUS:
$crowdInfo

SUPPORTED LANGUAGES:
1. English (en)
2. Hindi (hi)
3. Marathi (mr)
4. Gujarati (gu)
5. Bengali (bn)
6. Telugu (te)
7. Tamil (ta)
8. Kannada (kn)
9. Malayalam (ml)
10. Punjabi (pa)
11. Odia (or)
12. Assamese (as)
13. Urdu (ur)

CAPABILITIES:
1. Report lost persons - collect name, age, gender, height, clothing, last seen location, guardian info
2. Navigate to ghats and facilities
3. Find medical help, police, or other facilities
4. Provide general information about the event
5. Emergency SOS assistance

RULES:
- Be empathetic, especially for lost person cases.
- Ask ONE question at a time.
- Speak conversationally.
- Use the user's name ($name) when appropriate to be friendly.
- If the user asks "Where am I?", use the Current Location provided above.
- If the user asks about crowd, use the LIVE CROWD STATUS.
- Answer questions in a logical, step-by-step order.

LANGUAGE INTERACTION RULES:
- DETECT the language of the user's message.
- RESPOND in the SAME language as the user's message.
- If the user switches language, SWITCH your response language immediately.
- PREPEND a language tag to your response: [lang_code]
  - Example: "[en] Hello" or "[hi] Namaste" or "[mr] Namaskar"
- Do NOT output the tag in the spoken text, the system will parse it.

When enough data is collected for an action, respond with a JSON object in this EXACT format:

{
  "intent": "report_lost_person" | "navigation" | "find_facility" | "sos" | "general_query",
  "confidence": 0.0-1.0,
  "data": { ... },
  "missingFields": ["field1", "field2"],
  "nextQuestion": "What question to ask next if fields are missing"
}

For general queries, just respond conversationally with the [lang] tag.
''';
  }

  // Intent types
  static const String intentReportLostPerson = 'report_lost_person';
  static const String intentNavigation = 'navigation';
  static const String intentFindFacility = 'find_facility';
  static const String intentSOS = 'sos';
  static const String intentGeneralQuery = 'general_query';

  // Mock responses for testing (when API key is not available)
  static const Map<String, String> mockResponses = {
    'lost_person_initial':
        'I understand your concern. Let me help you file a report. Could you please tell me the name of the person who is lost?',
    'lost_person_age': 'Thank you. How old is [NAME]?',
    'lost_person_height': 'What is [NAME]\'s approximate height?',
    'lost_person_clothing':
        'Can you describe what [NAME] was wearing when you last saw them?',
    'lost_person_location': 'Where did you last see [NAME]?',
    'lost_person_complete':
        '{"intent":"report_lost_person","confidence":0.95,"data":{"name":"[NAME]","age":[AGE],"gender":"[GENDER]","height":"[HEIGHT]","clothing":"[CLOTHING]","lastSeenLocation":"[LOCATION]","guardianName":"[GUARDIAN]","guardianRelation":"[RELATION]"},"missingFields":[],"nextQuestion":""}',
    'navigation': 'I can help you navigate there. Let me open the map for you.',
    'sos':
        '🚨 I understand this is urgent. Let me find the nearest help for you immediately.',
    'general':
        'I\'m here to help you with information about the Kumbh Mela. What would you like to know?',
  };
}
