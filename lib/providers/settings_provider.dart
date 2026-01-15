import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User settings model
class UserSettings {
  final bool crowdLevelAlerts;
  final bool ritualReminders;
  final bool highContrastMode;
  final String language;
  final String textSize;
  final bool locationSharing;
  final bool dataBackupEnabled;

  const UserSettings({
    this.crowdLevelAlerts = true,
    this.ritualReminders = false,
    this.highContrastMode = false,
    this.language = 'English',
    this.textSize = 'Standard',
    this.locationSharing = false,
    this.dataBackupEnabled = true,
  });

  UserSettings copyWith({
    bool? crowdLevelAlerts,
    bool? ritualReminders,
    bool? highContrastMode,
    String? language,
    String? textSize,
    bool? locationSharing,
    bool? dataBackupEnabled,
  }) {
    return UserSettings(
      crowdLevelAlerts: crowdLevelAlerts ?? this.crowdLevelAlerts,
      ritualReminders: ritualReminders ?? this.ritualReminders,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      language: language ?? this.language,
      textSize: textSize ?? this.textSize,
      locationSharing: locationSharing ?? this.locationSharing,
      dataBackupEnabled: dataBackupEnabled ?? this.dataBackupEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crowdLevelAlerts': crowdLevelAlerts,
      'ritualReminders': ritualReminders,
      'highContrastMode': highContrastMode,
      'language': language,
      'textSize': textSize,
      'locationSharing': locationSharing,
      'dataBackupEnabled': dataBackupEnabled,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      crowdLevelAlerts: json['crowdLevelAlerts'] as bool? ?? true,
      ritualReminders: json['ritualReminders'] as bool? ?? false,
      highContrastMode: json['highContrastMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'English',
      textSize: json['textSize'] as String? ?? 'Standard',
      locationSharing: json['locationSharing'] as bool? ?? false,
      dataBackupEnabled: json['dataBackupEnabled'] as bool? ?? true,
    );
  }
}

/// Settings state notifier
class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier(this._userId) : super(const UserSettings()) {
    _loadSettings();
  }

  final String _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore
          .collection('user_settings')
          .doc(_userId)
          .get();

      if (doc.exists) {
        state = UserSettings.fromJson(doc.data()!);
      }
    } catch (e) {
      // Use defaults if load fails
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _firestore
          .collection('user_settings')
          .doc(_userId)
          .set(state.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Silently fail - will retry on next change
    }
  }

  void setCrowdLevelAlerts(bool value) {
    state = state.copyWith(crowdLevelAlerts: value);
    _saveSettings();
  }

  void setRitualReminders(bool value) {
    state = state.copyWith(ritualReminders: value);
    _saveSettings();
  }

  void setHighContrastMode(bool value) {
    state = state.copyWith(highContrastMode: value);
    _saveSettings();
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
    _saveSettings();
  }

  void setTextSize(String size) {
    state = state.copyWith(textSize: size);
    _saveSettings();
  }

  void setLocationSharing(bool value) {
    state = state.copyWith(locationSharing: value);
    _saveSettings();
  }

  void setDataBackupEnabled(bool value) {
    state = state.copyWith(dataBackupEnabled: value);
    _saveSettings();
  }

  Future<void> backupData() async {
    // TODO: Implement data backup logic
    await _saveSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  // Get current user ID from Firebase Auth
  final user = FirebaseAuth.instance.currentUser;
  final userId = user?.uid ?? 'anonymous_user';
  return SettingsNotifier(userId);
});
