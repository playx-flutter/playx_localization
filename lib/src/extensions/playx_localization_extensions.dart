import 'package:flutter/material.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/easy_localization/public.dart' as ez;

import '../easy_localization/localization.dart';

/// Strings extension method for access to [tr] and [plural()]
/// Example :
/// ```dart
/// 'title'.tr()
/// 'day'.plural(21)
extension PlayxLocalizationStringExtensions on String {
  /// An extension method for translating your language keys.
  /// Subscribes the widget on current [Localization] if [context] was provided.
  /// Otherwise, it may not listen to the current [Localization] changes.
  ///
  /// [args] List of localized strings. Replaces {} left to right
  /// [namedArgs] Map of localized strings. Replaces the name keys {key_name} according to its name
  /// [gender] Gender switcher. Changes the localized string based on gender string
  String tr({
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
    String? gender,
    Locale? locale,
  }) =>
      ez.tr(this,
          context: context, args: args, namedArgs: namedArgs, gender: gender, locale: locale);

  bool trExists() => ez.trExists(this);

  /// An extension method for translating your language keys with pluralization.
  /// Subscribes the widget on current [Localization] if context was provided.
  /// Otherwise, it may not listen to the current [Localization] changes.
  ///
  /// [value] Number value for pluralization
  /// [args] List of localized strings. Replaces {} left to right
  /// [namedArgs] Map of localized strings. Replaces the name keys {key_name} according to its name
  /// [name] Name of number value. Replaces {$name} to value
  /// [format] Formats a numeric value using a [NumberFormat](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html) class
  String plural(
    num value, {
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
    String? name,
    NumberFormat? format,
    Locale? locale,
  }) =>
      ez.plural(
        this,
        value,
        args: args,
        namedArgs: namedArgs,
        name: name,
        format: format,
        context: context,
        locale: locale,
      );
}

/// Text widget extension method for access to [tr()] and [plural()]
/// Example :
/// ```dart
/// Text('title').tr()
/// Text('day').plural(21)
/// ```
extension TextTranslateExtension on Text {
  /// {@macro tr}
  Text tr(
          {List<String>? args,
          BuildContext? context,
          Map<String, String>? namedArgs,
          String? gender,
          Locale? locale}) =>
      Text(
          ez.tr(
            data ?? '',
            args: args,
            namedArgs: namedArgs,
            gender: gender,
            context: context,
            locale: locale,
          ),
          key: key,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis);

  /// {@macro plural}
  Text plural(
    num value, {
    BuildContext? context,
    List<String>? args,
    Map<String, String>? namedArgs,
    String? name,
    NumberFormat? format,
    Locale? locale,
  }) =>
      Text(
          ez.plural(
            data ?? '',
            context: context,
            value,
            args: args,
            namedArgs: namedArgs,
            name: name,
            format: format,
            locale: locale,
          ),
          key: key,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis);
}

extension BuildContextLocalizationExtension on BuildContext {
  /// An extension method for translating your language keys.
  /// Subscribes the widget on current [Localization] that provided from context.
  /// Throws exception if [Localization] was not found.
  ///
  /// [key] Localization key
  /// [args] List of localized strings. Replaces {} left to right
  /// [namedArgs] Map of localized strings. Replaces the name keys {key_name} according to its name
  /// [gender] Gender switcher. Changes the localized string based on gender string
  ///
  /// Example:
  ///
  /// ```json
  /// {
  ///    "msg":"{} are written in the {} language",
  ///    "msg_named":"Easy localization is written in the {lang} language",
  ///    "msg_mixed":"{} are written in the {lang} language",
  ///    "gender":{
  ///       "male":"Hi man ;) {}",
  ///       "female":"Hello girl :) {}",
  ///       "other":"Hello {}"
  ///    }
  /// }
  /// ```
  /// ```dart
  /// Text(context.tr('msg', args: ['Easy localization', 'Dart']), // args
  /// Text(context.tr('msg_named', namedArgs: {'lang': 'Dart'}),   // namedArgs
  /// Text(context.tr('msg_mixed', args: ['Easy localization'], namedArgs: {'lang': 'Dart'}), // args and namedArgs
  /// Text(context.tr('gender', gender: _gender ? "female" : "male"), // gender
  /// ```
  String tr(
    String key, {
    List<String>? args,
    Map<String, String>? namedArgs,
    String? gender,
    Locale? locale,
  }) {
    final localization = Localization.of(this);

    if (localization == null) {
      throw Exception('Localization not found for current context.');
    }

    return localization.tr(
      key,
      args: args,
      namedArgs: namedArgs,
      gender: gender,
      locale: locale,
    );
  }

  /// An extension method for translating your language keys with pluralization.
  /// Subscribes the widget on current [Localization] that provided from context.
  /// Throws exception if [Localization] was not found.
  ///
  /// [key] Localization key
  /// [value] Number value for pluralization
  /// [args] List of localized strings. Replaces {} left to right
  /// [namedArgs] Map of localized strings. Replaces the name keys {key_name} according to its name
  /// [name] Name of number value. Replaces {$name} to value
  /// [format] Formats a numeric value using a [NumberFormat](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html) class
  String plural(
    String key,
    num number, {
    List<String>? args,
    Map<String, String>? namedArgs,
    String? name,
    NumberFormat? format,
    Locale? locale,
  }) {
    final localization = Localization.of(this);

    if (localization == null) {
      throw Exception('Localization not found for current context.');
    }

    return localization.plural(
      key,
      number,
      args: args,
      namedArgs: namedArgs,
      name: name,
      format: format,
      locale: locale,
    );
  }

  /// Returns the current `XLocale` object with locale and font info.
  XLocale get currentXLocale {
    final locale = PlayxInheritedLocalization.of(this);
    return locale.locale;
  }

  /// Returns the current [Locale] used in the app.
  Locale get currentLocale => currentXLocale.locale;

  /// Returns the locale as a BCP-47 language tag (e.g., `en-US`, `ar-EG`).
  String get localeTag => currentLocale.toLanguageTag();

  /// Returns the current locale's language code (e.g., 'en', 'ar').
  String get currentLanguageCode => currentLocale.languageCode;

  /// Returns the font family for the current locale, if provided.
  String? get fontFamily => currentXLocale.fontFamily;

  /// Returns true if the current locale is Arabic.
  bool get isCurrentLocaleArabic => currentLanguageCode == 'ar';

  /// Returns true if the current locale is English.
  bool get isCurrentLocaleEnglish => currentLanguageCode == 'en';

  /// Returns true if the current locale is RTL (e.g., Arabic, Hebrew).
  bool get isCurrentLocaleRtl => Bidi.hasAnyRtl(currentLanguageCode);

  /// Returns true if the current locale is LTR.
  bool get isCurrentLocaleLtr => !isCurrentLocaleRtl;

  /// Returns true if the app is currently synced to the device locale.
  bool get isDeviceLocaleSelected => PlayxLocalization.isDeviceLocaleSelected;
}
