import 'dart:ui';

import '../../playx_localization.dart';

extension LocaleExtension on Locale {
  bool supports(Locale locale) {
    if (this == locale) {
      return true;
    }
    if (languageCode != locale.languageCode) {
      return false;
    }
    if (countryCode != null &&
        countryCode!.isNotEmpty &&
        countryCode != locale.countryCode) {
      return false;
    }
    if (scriptCode != null && scriptCode != locale.scriptCode) {
      return false;
    }

    return true;
  }

  /// The locale as `language[-script][-country]` (BCP-47 order, e.g.
  /// `zh-Hant-TW`) joined with [separator].
  String toStringWithSeparator({String separator = '-'}) {
    final parts = <String>[];
    if (languageCode.isNotEmpty) {
      parts.add(languageCode);
    }
    if (scriptCode != null && scriptCode!.isNotEmpty) {
      parts.add(scriptCode!);
    }
    if (countryCode != null && countryCode!.isNotEmpty) {
      parts.add(countryCode!);
    }
    return parts.join(separator);
  }

  /// The order used before 0.5.0: `language[-country][-script]`
  /// (e.g. `zh-TW-Hant`). Only differs from [toStringWithSeparator] when both
  /// a country and a script code are set. Used to keep old asset names working.
  String toLegacyStringWithSeparator({String separator = '-'}) {
    final parts = <String>[];
    if (languageCode.isNotEmpty) {
      parts.add(languageCode);
    }
    if (countryCode != null && countryCode!.isNotEmpty) {
      parts.add(countryCode!);
    }
    if (scriptCode != null && scriptCode!.isNotEmpty) {
      parts.add(scriptCode!);
    }
    return parts.join(separator);
  }
}

extension XLocaleExtension on XLocale {
  Locale get locale {
    if (scriptCode != null && scriptCode!.isNotEmpty) {
      return Locale.fromSubtags(
        languageCode: languageCode,
        countryCode: countryCode,
        scriptCode: scriptCode,
      );
    }
    return Locale(languageCode, countryCode);
  }

  String toStringWithSeparator({String separator = '-'}) {
    return locale.toStringWithSeparator(separator: separator);
  }
}
