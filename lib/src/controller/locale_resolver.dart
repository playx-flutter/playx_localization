import 'dart:ui';

import '../config/playx_locale_config.dart';
import '../extensions/locale_extensions.dart';
import '../model/x_locale.dart';
import 'locale_persistence.dart';

/// The locale the app should start with.
///
/// [fromLegacyIndex] is true when it was restored from an index saved by an
/// older version, so it should be saved again by id.
typedef ResolvedLocale = ({
  XLocale locale,
  bool isDeviceSelected,
  bool fromLegacyIndex,
});

/// Pure helpers that decide which locale to use for a [PlayxLocaleConfig].
/// They hold no state so they are easy to test.
abstract final class LocaleResolver {
  /// The fallback locale: the configured one, else English if supported, else
  /// the first supported locale.
  static XLocale fallbackLocale(PlayxLocaleConfig config) {
    if (config.fallbackLocale != null) return config.fallbackLocale!;
    for (final l in config.supportedLocales) {
      if (l.languageCode == 'en') return l;
    }
    return config.supportedLocales.first;
  }

  /// The supported locale matching [languageCode], [countryCode] and
  /// [scriptCode], or else one with the same language code.
  static XLocale? search(
    PlayxLocaleConfig config, {
    required String languageCode,
    String? countryCode,
    String? scriptCode,
  }) {
    final wanted = Locale.fromSubtags(
        languageCode: languageCode,
        countryCode: countryCode,
        scriptCode: scriptCode);
    for (final l in config.supportedLocales) {
      if (l.locale.supports(wanted)) return l;
    }
    for (final l in config.supportedLocales) {
      if (l.languageCode == languageCode) return l;
    }
    return null;
  }

  /// The supported locale for the [device] locale, if any.
  static XLocale? matchDevice(PlayxLocaleConfig config, Locale? device) {
    if (device == null) return null;
    for (final l in config.supportedLocales) {
      if (l.locale.supports(device)) return l;
    }
    for (final l in config.supportedLocales) {
      if (l.languageCode == device.languageCode) return l;
    }
    return null;
  }

  /// The locale to use when nothing is saved: the configured `startLocale`
  /// (unless the app follows the device), then the device locale, then the
  /// fallback locale.
  static XLocale defaultLocale(
    PlayxLocaleConfig config, {
    required Locale? deviceLocale,
    bool followDevice = false,
  }) {
    if (!followDevice && config.startLocale != null) return config.startLocale!;
    return matchDevice(config, deviceLocale) ?? fallbackLocale(config);
  }

  /// Decides the locale to boot with from what was saved.
  ///
  /// - A saved id wins. If that id no longer exists (the locale was removed)
  ///   the saved choice is dropped; the index is *not* used, since it would
  ///   point to a different language.
  /// - Without an id, the legacy index of older versions is used.
  /// - The device marker (or legacy index `-1`) follows the device locale.
  /// - With nothing usable saved, [defaultLocale] is used.
  static ResolvedLocale resolveBoot(
    PlayxLocaleConfig config, {
    required SavedLocale saved,
    required Locale? deviceLocale,
  }) {
    final locales = config.supportedLocales;
    final followDevice = saved.id == LocalePersistence.deviceMarker ||
        (saved.id == null && saved.index == -1);

    if (!followDevice) {
      final id = saved.id;
      if (id != null) {
        for (final l in locales) {
          if (l.id == id) {
            return (locale: l, isDeviceSelected: false, fromLegacyIndex: false);
          }
        }
      } else {
        final index = saved.index;
        if (index != null && index >= 0 && index < locales.length) {
          return (
            locale: locales[index],
            isDeviceSelected: false,
            fromLegacyIndex: true,
          );
        }
      }
    }

    return (
      locale: defaultLocale(config,
          deviceLocale: deviceLocale, followDevice: followDevice),
      isDeviceSelected: followDevice,
      fromLegacyIndex: false,
    );
  }
}
