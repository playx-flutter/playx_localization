import 'dart:ui';

import 'package:intl/intl.dart';

import '../../playx_localization.dart';

/// Extension on [String] to help with localization and language-specific analysis.
extension LocalizationStringExtensions on String {
  /// Returns `true` if the string contains any **right-to-left** characters (e.g. Arabic, Hebrew).
  bool get isRtl => Bidi.hasAnyRtl(this);

  /// Returns `true` if the string does **not** contain RTL characters.
  bool get isLtr => !isRtl;

  /// Regular expression for matching **any English letters** (a–z or A–Z).
  static final RegExp _englishRegExp = RegExp(r'[a-zA-Z]');

  /// Regular expression for matching **any Arabic letters** (includes Arabic and Arabic Supplement Unicode blocks).
  static final RegExp _arabicRegExp = RegExp(r'[\u0600-\u06FF\u0750-\u077F]');

  /// Regular expression for matching **only Arabic letters** (ignores digits or punctuation).
  static final RegExp _onlyArabicRegExp = RegExp(r'^[\u0600-\u06FF\s]+$');

  /// Regular expression for matching **only English letters**.
  static final RegExp _onlyEnglishRegExp = RegExp(r'^[a-zA-Z\s]+$');

  /// Regular expression to check for any digits.
  static final RegExp _numberRegExp = RegExp(r'[0-9]');

  /// Returns `true` if the string contains **any English** letters.
  bool get isEnglish => _englishRegExp.hasMatch(this);

  /// Returns `true` if the string contains **any Arabic** letters.
  bool get isArabic => _arabicRegExp.hasMatch(this);

  /// Returns `true` if the string contains **only Arabic** letters (and spaces).
  bool get containsOnlyArabic => _onlyArabicRegExp.hasMatch(this.trim());

  /// Returns `true` if the string contains **only English** letters (and spaces).
  bool get containsOnlyEnglish => _onlyEnglishRegExp.hasMatch(this.trim());

  /// Returns `true` if the string contains **any numeric** digits.
  bool get hasNumbers => _numberRegExp.hasMatch(this);


  /// A list of Arabic diacritics (tashkeel) used in the Arabic language.
  static const List<String>      _diacritics = [
    '\u064B', // fathatan
    '\u064C', // dammatan
    '\u064D', // kasratan
    '\u064E', // fatha
    '\u064F', // damma
    '\u0650', // kasra
    '\u0651', // shadda
    '\u0652', // sukun
    '\u0653', // maddah above
    '\u0654', // hamza above
    '\u0655', // hamza below
  ];

  /// Removes **Arabic diacritics (tashkeel)** from the string.
  ///
  /// Useful for comparing Arabic words or simplifying them.
  String get stripDiacritics {
    return replaceAll(RegExp('[${_diacritics.join()}]'), '');
  }

  /// Converts European digits to Arabic-Indic digits.
  String toArabicIndicDigits() {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    var result = this;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  /// Converts Arabic-Indic digits to English digits.
  String toEnglishDigits() {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    var result = this;
    for (int i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], english[i]);
    }
    return result;
  }

  /// Converts the string to localized digits based on the current locale.
  String toLocalizedDigits({String? locale, bool toArabic = true}) {
    final formatLocale = locale ?? PlayxLocalization.currentLocale.toLanguageTag();
    if (formatLocale.startsWith('ar') && toArabic) {
      return toArabicIndicDigits();
    }
    return toEnglishDigits();
  }

  /// Normalizes Arabic characters like Alef forms to a standard form.
  String normalizeArabicLetters() {
    return replaceAll(RegExp('[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  /// Removes redundant spaces from the string.
  String removeExtraSpaces() {
    return trim().replaceAll(RegExp(r'\s+'), ' ');
  }


  /// Convert string to [Locale] object
  Locale toLocale({String separator = '_'}) {
    final localeList = split(separator);
    switch (localeList.length) {
      case 2:
        return localeList.last.length == 4 // scriptCode length is 4
            ? Locale.fromSubtags(
          languageCode: localeList.first,
          scriptCode: localeList.last,
        )
            : Locale(localeList.first, localeList.last);
      case 3:
        return Locale.fromSubtags(
          languageCode: localeList.first,
          scriptCode: localeList[1],
          countryCode: localeList.last,
        );
      default:
        return Locale(localeList.first);
    }
  }

}
