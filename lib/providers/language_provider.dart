import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the current application locale
class LanguageState {
  final Locale locale;
  final bool isSelected;
  const LanguageState({required this.locale, this.isSelected = false});
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return LanguageNotifier(prefs);
  },
);

class LanguageNotifier extends StateNotifier<LanguageState> {
  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs)
    : super(const LanguageState(locale: Locale('en'))) {
    _loadLocale();
  }

  static const String _kLanguageCode = 'language_code';
  static const String _kLanguageSelected = 'language_selected';

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('mr'), // Marathi
    Locale('gu'), // Gujarati
    Locale('bn'), // Bengali
    Locale('te'), // Telugu
    Locale('ta'), // Tamil
    Locale('kn'), // Kannada
    Locale('ml'), // Malayalam
    Locale('pa'), // Punjabi
    Locale('or'), // Odia
    Locale('as'), // Assamese
    Locale('ur'), // Urdu
  ];

  void _loadLocale() {
    final String? languageCode = _prefs.getString(_kLanguageCode);
    final bool isSelected = _prefs.getBool(_kLanguageSelected) ?? false;

    if (languageCode != null) {
      state = LanguageState(
        locale: Locale(languageCode),
        isSelected: isSelected,
      );
    } else {
      state = LanguageState(locale: const Locale('en'), isSelected: isSelected);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    state = LanguageState(locale: locale, isSelected: true);
    await _prefs.setString(_kLanguageCode, locale.languageCode);
    await _prefs.setBool(_kLanguageSelected, true);
  }
}
