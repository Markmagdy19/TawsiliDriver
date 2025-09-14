// language_manager.dart (content remains unchanged)
import 'package:flutter/material.dart';

enum LanguageType { ENGLISH, ARABIC }

const String ARABIC_CODE = "ar";
const String ENGLISH_CODE = "en";
const String ASSET_PATH_LOCALIZATIONS = "assets/translations";

const Locale ARABIC_LOCAL = Locale("ar");
const Locale ENGLISH_LOCAL = Locale("en");

extension LanguageTypeExtension on LanguageType {
  String getValue() {
    switch (this) {
      case LanguageType.ENGLISH:
        return ENGLISH_CODE;
      case LanguageType.ARABIC:
        return ARABIC_CODE;
    }
  }
}