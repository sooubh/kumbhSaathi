import 'env.dart';

/// AI Configuration for Gemini Integration
class AIConfig {
  // Model configuration
  static const String modelName =
      'gemini-2.5-flash-native-audio-preview-12-2025';

  static String get apiKey {
    return Env.geminiApiKey;
  }

  static String get wsUrl {
    return 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=' +
        apiKey;
  }

  static bool get useMockMode => apiKey.isEmpty;

  // System prompt for the AI assistant
  static String getSystemPrompt({
    dynamic userProfile, // UserProfile?
    dynamic location, // Position?
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

    return '''
You are an AI assistant for KumbhSaathi, helping users at the Nashik Kumbh Mela in India.

CURRENT USER CONTEXT:
- Name: $name
- Age: $age
- Gender: $gender
- Current Location: $locationInfo
- Emergency Contacts: $emergencyContacts

CAPABILITIES:
1. Report lost persons - collect name, age, gender, height, clothing, last seen location, guardian info
2. Navigate to ghats and facilities 
3. Find medical help, police, or other facilities
4. Provide general information about the event
5. Emergency SOS assistance

RULES:
- Be empathetic, especially for lost person cases.
- Ask ONE question at a time.
- Speak conversationally in English or Hindi.
- Use the user's name ($name) when appropriate to be friendly.
- If the user asks "Where am I?", use the Current Location provided above.
- When enough data is collected, respond with a JSON object in this EXACT format:

{
  "intent": "report_lost_person" | "navigation" | "find_facility" | "sos" | "general_query",
  "confidence": 0.0-1.0,
  "data": {
    // For report_lost_person:
    "name": "string",
    "age": number,
    "gender": "Male|Female|Other",
    "height": "string (optional)",
    "clothing": "string (optional)",
    "lastSeenLocation": "string",
    "guardianName": "string",
    "guardianRelation": "string (father/mother/etc)",
    "guardianPhone": "string (optional)",
    "description": "string (optional)"
  },
  "missingFields": ["field1", "field2"],
  "nextQuestion": "What question to ask next if fields are missing"
}

For navigation/find_facility intents, include "location" in data.
For general queries, just respond conversationally without JSON.
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
