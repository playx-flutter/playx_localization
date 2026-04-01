import 'package:flutter/material.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/extensions/locale_extensions.dart';
import 'package:playx_localization/src/model/x_locale.dart';

import 'config/playx_locale_config.dart';

/// PlayxLocalization :
/// Used to update current app locale with id, index, device locale and more.
/// And holds reference to the current app locale.
/// With other utilities to be used.
/// Must be initialized by calling [boot] before calling any method.
abstract class PlayxLocalization {
  /// The current PlayxLocaleController instance getter .
  /// Throws exception if not initialized.
  static PlayxLocaleController get _controller =>
      PlayxLocaleController.controller;

  ///Setup the current app locales with your configuration.
  ///And loads app supported translations.
  /// Must be called before calling any other method to initialize dependencies.
  static Future<void> boot({
    required PlayxLocaleConfig config,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final controller = PlayxLocaleController(config: config);
    return controller.boot();
  }

  ///returns the current supported xLocales.
  static List<XLocale> get supportedXLocales => _controller.supportedXLocales;

  /// Returns the current supported locales.
  static List<Locale> get supportedLocales => _controller.supportedLocales;

  /// Returns current locale index.
  static int get currentIndex => _controller.currentIndex;

  ///Returns current [XLocale] that is used in the app.
  static XLocale get currentXLocale {
    final value = _controller.value;
    if (value == null) {
      throw Exception(
          'Localization has not been initialized. You must call boot method before accessing any property.');
    }
    return value;
  }

  /// Returns the current [Locale] that is used in the app.
  static Locale get currentLocale => _controller.value!.locale;

  /// Returns the locale of device.
  static Locale? get deviceLocale => _controller.deviceLocale;

  /// Returns whether the app locale is actively synced to the device locale.
  static bool get isDeviceLocaleSelected => _controller.isDeviceLocaleSelected;

  /// Returns the current fallback Locale that is used in the app.
  /// If [useFallbackTranslations] in config is false, it will return null.
  /// Else it will return the fallback locale based on config.
  /// If no fallback locale is found, it will use english locale if found.
  /// If no english locale is found, it will return the first locale in the supported locales list.
  /// If no supported locales are found, it will return null.
  static XLocale? get fallbackLocale =>
      _controller.config.useFallbackTranslations
          ? _controller.getFallbackLocale()
          : null;

  /// Switch the locale to the next in the supported locales list
  /// if there is no next locale, it will switch to the first one
  static Future<void> nextLocale({bool forceAppUpdate = false}) =>
      _controller.nextLocale(forceAppUpdate: forceAppUpdate);

  ///Update the locale to be one of the supported locales.
  static Future<bool> updateTo(XLocale locale, {bool forceAppUpdate = false}) =>
      _controller.updateTo(locale, forceAppUpdate: forceAppUpdate);

  /// Update the locale by index
  static Future<bool> updateByIndex(int index, {bool forceAppUpdate = false}) =>
      _controller.updateByIndex(index, forceAppUpdate: forceAppUpdate);

  /// update the theme to by id
  static Future<bool> updateById(String id, {bool forceAppUpdate = false}) =>
      _controller.updateById(id, forceAppUpdate: forceAppUpdate);

  /// update the locale by language code and country code if available.
  static Future<bool> updateByLanguageCode(
          {required String languageCode,
          String? countryCode,
          bool forceAppUpdate = false}) =>
      _controller.updateByLanguageCode(
          languageCode: languageCode,
          countryCode: countryCode,
          forceAppUpdate: forceAppUpdate);

  /// Updates the locale to current device locale.
  static Future<bool> updateToDeviceLocale({bool forceAppUpdate = false}) =>
      _controller.updateToDeviceLocale(forceAppUpdate: forceAppUpdate);

  ///Check if current locale is arabic.
  static bool isCurrentLocaleArabic() => _controller.isCurrentLocaleArabic();

  ///Check if current locale is english.
  static bool isCurrentLocaleEnglish() => _controller.isCurrentLocaleEnglish();

  ///Check if current locale is rtl.
  static bool isCurrentLocaleRtl() => _controller.isCurrentLocaleRtl();

  /// Convert current [locale] to String with custom [separator] representing language code and country code.
  String currentLocaleToString({String separator = '_'}) =>
      _controller.currentLocaleToString(separator: separator);

  ///delete saved locale from device storage.
  static Future<void> deleteSavedLocale() => _controller.deleteSavedLocale();

  //delegates to be used in material app.
  static List<LocalizationsDelegate> get localizationDelegates =>
      _controller.delegates;
}
