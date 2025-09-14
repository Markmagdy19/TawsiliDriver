import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_preference.dart';
import 'language_manager.dart';



class LocaleNotifier extends StateNotifier<Locale> {
  final AppPreferences _appPreferences;

  LocaleNotifier(this._appPreferences) : super(ENGLISH_LOCAL) {
    print('DEBUG: [LocaleNotifier] Initialized with default state: ${state.languageCode}');
  }

  Future<void> setLocale(BuildContext context, Locale newLocale) async {
    print('DEBUG: [LocaleNotifier] setLocale called with newLocale: ${newLocale.languageCode}'); // Debug print

    state = newLocale;
    print('DEBUG: [LocaleNotifier] Riverpod state updated to: ${state.languageCode}'); // Debug print


    await _appPreferences.setAppLanguage(newLocale.languageCode);

    await context.setLocale(newLocale);
    print('DEBUG: [LocaleNotifier] EasyLocalization context locale is now: ${context.locale.languageCode}'); // Debug print

    if (state.languageCode != context.locale.languageCode) {
      print('WARNING: [LocaleNotifier] Riverpod state and EasyLocalization context locale are out of sync!');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final appPreferences = ref.watch(appPreferencesProvider);
  return LocaleNotifier(appPreferences);
});