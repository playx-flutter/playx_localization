import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/easy_localization/translations.dart';

class TranslationManager {
  TranslationManager._();

  static Future<
      ({
        Translations? translations,
        Translations? fallbackTranslations,
      })> loadTranslations({
    required XLocale locale,
    bool useFallbackTranslations = true,
    required PlayxLocaleConfig config,
    required XLocale fallbackLocale,
  }) async {
    Map<String, dynamic> data;
    try {
      data =
          Map.from(await loadTranslationData(locale: locale, config: config));
      final translations = Translations(data);
      if (useFallbackTranslations) {
        Map<String, dynamic>? baseLangData;
        if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
          baseLangData =
              await loadBaseLangTranslationData(locale: locale, config: config);
        }
        data = Map.from(
            await loadTranslationData(locale: fallbackLocale, config: config));
        if (baseLangData != null) {
          try {
            data.addAll(baseLangData);
          } on UnsupportedError {
            data = Map.of(data)..addAll(baseLangData);
          }
        }
        final fallbackTranslations = Translations(data);
        return (
          translations: translations,
          fallbackTranslations: fallbackTranslations
        );
      }
      return (translations: translations, fallbackTranslations: null);
    } on FlutterError catch (e, s) {
      // onLoadError(e);
      PlayxLocaleController.logger
          ?.error('Error loading translations: ', error: e, stackTrace: s);
      return (translations: null, fallbackTranslations: null);
    } catch (e, s) {
      PlayxLocaleController.logger
          ?.error('Error loading translations: ', error: e, stackTrace: s);
      // onLoadError(FlutterError(e.toString()));
      return (
        translations: null,
        fallbackTranslations: null,
      );
    }
  }

  static Future<Map<String, dynamic>?> loadBaseLangTranslationData(
      {required XLocale locale, required PlayxLocaleConfig config}) async {
    try {
      return await loadTranslationData(locale: locale, config: config);
    } on FlutterError catch (e, s) {
      // Disregard asset not found FlutterError when attempting to load base language fallback
      PlayxLocaleController.logger
          ?.error('Error loading translations: ', error: e, stackTrace: s);
    }
    return null;
  }

  static Future<Map<String, dynamic>> loadTranslationData(
      {required XLocale locale, required PlayxLocaleConfig config}) async {
    late Map<String, dynamic>? data;

    if (config.useOnlyLangCode) {
      data = await config.assetLoader
          .load(config.path, Locale(locale.languageCode));
    } else {
      data = await config.assetLoader.load(config.path, locale.locale);
    }

    if (data == null) return {};

    return data;
  }
}
