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

  String toStringWithSeparator({String separator = '-'}) {
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
  Locale get locale => Locale(languageCode, countryCode);

  String toStringWithSeparator({String separator = '-'}) {
    return locale.toStringWithSeparator(separator: separator);
  }


}