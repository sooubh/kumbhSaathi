/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'KumbhSaathi';
  static const String appSubtitle = 'Nashik Kumbh 2025';
  static const String appVersion = '1.0.0';

  // API Endpoints (placeholder)
  static const String baseUrl = 'https://api.kumbhsaathi.com';

  // Emergency Numbers
  static const String emergencyNumber = '112';
  static const String melaHqNumber = '+91-1234567890';
  static const String policeNumber = '100';
  static const String ambulanceNumber = '108';

  // Map Settings
  static const double defaultMapZoom = 15.0;
  static const double nashikLat = 20.0063;
  static const double nashikLng = 73.7897;

  // Crowd Levels
  static const int crowdLevelLow = 30;
  static const int crowdLevelMedium = 60;
  static const int crowdLevelHigh = 80;

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'app_language';
  static const String userProfileKey = 'user_profile';
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // SOS Settings
  static const int sosHoldDuration = 3; // seconds

  // Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
  ];
}
