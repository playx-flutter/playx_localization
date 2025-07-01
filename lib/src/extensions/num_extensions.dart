import 'dart:math';

import 'package:intl/intl.dart';
import 'package:playx_localization/src/playx_localization.dart';

/// Extension functions to help perform common operations and formatting on [num] values.
extension NumExtensions on num {
  /// Rounds the number to the given number of decimal places.
  ///
  /// Example:
  /// ```dart
  /// 3.14159.roundToPrecision(numbersToRoundTo: 2); // → 3.14
  /// ```
  double roundToPrecision({int numbersToRoundTo = 2}) {
    final factor = pow(10, numbersToRoundTo).toInt();
    return (this * factor).round() / factor;
  }

  /// Formats the number using a custom pattern and locale, optionally prefixing with a currency symbol.
  ///
  /// Example:
  /// ```dart
  /// 1000000.toFormattedCurrencyNumber(currencySymbol: '\$', locale: 'en');
  /// // → $1,000,000.00
  /// ```
  String toFormattedCurrencyNumber({
    String format = "#,##0.00##",
    String locale = 'en',
    String? currencySymbol,
  }) {
    final numberFormat = NumberFormat(format, locale);
    final formatted = numberFormat.format(this);
    return currencySymbol != null ? '$currencySymbol$formatted' : formatted;
  }

  /// Formats the number as a currency string using the current locale from [PlayxLocalization].
  ///
  /// Defaults to Arabic (`ar_EG`) if current locale is Arabic.
  String toLocalizedCurrencyNumber({
    String format = "#,##0.00##",
    String? locale,
    String? currencySymbol,
  }) {
    final formatLocale = locale ??
        (PlayxLocalization.isCurrentLocaleArabic()
            ? 'ar_EG'
            : PlayxLocalization.currentLocale.toLanguageTag());

    final numberFormat = NumberFormat(format, formatLocale);
    final formatted = numberFormat.format(this);
    return currencySymbol != null ? '$currencySymbol$formatted' : formatted;
  }

  /// Formats the number using the given pattern and locale.
  ///
  /// Example:
  /// ```dart
  /// 1234.56.toFormattedNumber(format: "#,##0.0", locale: "en_US"); // → 1,234.6
  /// ```
  String toFormattedNumber({
    required String format,
    String locale = 'en',
  }) {
    final numberFormat = NumberFormat(format, locale);
    return numberFormat.format(this);
  }

  /// Formats the number using Arabic numerals with optional format.
  ///
  /// Example:
  /// ```dart
  /// 123.toLocalizedArabicNumber(); // → ١٢٣
  /// ```
  String toLocalizedArabicNumber({String format = '#.##'}) {
    return NumberFormat(format, 'ar_EG').format(this);
  }

  /// Formats the number using English numerals with optional format.
  ///
  /// Example:
  /// ```dart
  /// 123.toLocalizedEnglishNumber(); // → 123
  /// ```
  String toLocalizedEnglishNumber({String format = '#.##'}) {
    return NumberFormat(format, 'en_US').format(this);
  }

  /// Formats the number using Arabic or English numerals depending on the current locale.
  ///
  /// Useful for localizing number format without manually checking the locale.
  String toLocalizedArabicOrEnglishNumber({String format = '#.##'}) {
    return PlayxLocalization.isCurrentLocaleArabic()
        ? toLocalizedArabicNumber(format: format)
        : toLocalizedEnglishNumber(format: format);
  }

  /// Formats the number according to the given or current locale and format.
  ///
  /// If [locale] is not provided, it uses the current locale from [PlayxLocalization].
  String toLocalizedNumber({
    String? locale,
    String format = '#.##',
  }) {
    final formatLocale =
        locale ?? PlayxLocalization.currentLocale.toLanguageTag();
    return NumberFormat(format, formatLocale).format(this);
  }

  /// Returns `true` if the number is equal to 0 within a small tolerance (useful for floating-point precision).
  ///
  /// Example:
  /// ```dart
  /// (0.00000001).isZero(); // → true
  /// ```
  bool isZero({double precision = 1e-8}) => abs() < precision;
}
