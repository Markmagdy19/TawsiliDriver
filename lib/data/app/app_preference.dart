// app_preference.dart (content remains as previously fixed/discussed)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/resources/language/language_manager.dart';


const String PREFS_KEY_LANG = "PREFS_KEY_LANG";
const String PREFS_KEY_ONBOARDING_SCREEN_VIEWED =
    "PREFS_KEY_ONBOARDING_SCREEN_VIEWED";
const String PREFS_KEY_IS_USER_LOGGED_IN = "PREFS_KEY_IS_USER_LOGGED_IN";

// Provider for SharedPreferences instance
// It's a FutureProvider because SharedPreferences.getInstance() is async
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  print('DEBUG: [AppPreferences] sharedPreferencesProvider: Getting instance...');
  final instance = await SharedPreferences.getInstance();
  print('DEBUG: [AppPreferences] sharedPreferencesProvider: Instance obtained.');
  return instance;
});

// Provider for AppPreferences instance, depends on sharedPreferencesProvider
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  final sharedPrefsAsync = ref.watch(sharedPreferencesProvider);

  return sharedPrefsAsync.when(
    data: (sharedPrefs) {
      print('DEBUG: [AppPreferences] appPreferencesProvider: Creating AppPreferences with loaded SharedPreferences.');
      return AppPreferences(sharedPrefs);
    },
    loading: () {
      print('DEBUG: [AppPreferences] appPreferencesProvider: SharedPreferences still loading...');
      throw Exception("SharedPreferences not loaded yet for AppPreferences");
    },
    error: (err, stack) {
      print('ERROR: [AppPreferences] appPreferencesProvider: Error loading SharedPreferences: $err');
      throw Exception("Error loading SharedPreferences: $err");
    },
  );
});

class AppPreferences {
  final SharedPreferences _sharedPreferences;

  AppPreferences(this._sharedPreferences) {
    print('DEBUG: [AppPreferences] AppPreferences: Initialized.');
  }

  Future<void> setAppLanguage(String langCode) async {
    print('DEBUG: [AppPreferences] AppPreferences: Attempting to save language: $langCode');
    await _sharedPreferences.setString(PREFS_KEY_LANG, langCode);
    final savedLang = _sharedPreferences.getString(PREFS_KEY_LANG);
    print('DEBUG: [AppPreferences] AppPreferences: Saved language verification: $savedLang');
  }

  Future<Locale> getLocal() async {
    final language = _sharedPreferences.getString(PREFS_KEY_LANG);
    print('DEBUG: [AppPreferences] AppPreferences: Retrieved language from prefs (sync read): $language');

    if (language == null || language.isEmpty) {
      print('DEBUG: [AppPreferences] AppPreferences: No language found in prefs, defaulting to English.');
      return ENGLISH_LOCAL;
    }

    if (language == ARABIC_CODE) {
      print('DEBUG: [AppPreferences] AppPreferences: Language from prefs is Arabic.');
      return ARABIC_LOCAL;
    } else {
      print('DEBUG: [AppPreferences] AppPreferences: Language from prefs is English (or unknown, defaulting).');
      return ENGLISH_LOCAL;
    }
  }

  Future<void> setOnBoardingScreenViewed() async {
    await _sharedPreferences.setBool(PREFS_KEY_ONBOARDING_SCREEN_VIEWED, true);
  }

  bool isOnBoardingScreenViewed() {
    return _sharedPreferences.getBool(PREFS_KEY_ONBOARDING_SCREEN_VIEWED) ?? false;
  }

  Future<void> setUserLoggedIn() async {
    await _sharedPreferences.setBool(PREFS_KEY_IS_USER_LOGGED_IN, true);
  }

  bool isUserLoggedIn() {
    return _sharedPreferences.getBool(PREFS_KEY_IS_USER_LOGGED_IN) ?? false;
  }

  Future<void> logout() async {
    await _sharedPreferences.remove(PREFS_KEY_IS_USER_LOGGED_IN);
    await _sharedPreferences.remove(PREFS_KEY_LANG); // Clear language on logout
  }
}