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
    final result = <String, dynamic>{};
    final loaderFutures = <Future<Map<String, dynamic>?>>[];

    final Locale desiredLocale = config.useOnlyLangCode
        ? Locale.fromSubtags(
            languageCode: locale.languageCode, scriptCode: locale.scriptCode)
        : locale.locale;

    List<AssetLoader> loaders = [
      config.assetLoader,
      if (config.extraAssetLoaders != null) ...config.extraAssetLoaders!
    ];

    for (final loader in loaders) {
      loaderFutures.add(loader.load(config.path, desiredLocale));
    }

    await Future.wait(loaderFutures).then((List<Map<String, dynamic>?> value) {
      for (final Map<String, dynamic>? map in value) {
        if (map != null) {
          result.addAllRecursive(map);
        }
      }
    });

    return result;
  }
}

extension MapExtension on Map<String, dynamic> {
  void addAllRecursive(Map<String, dynamic> other) {
    other.forEach((key, value) {
      if (this[key] == null) {
        this[key] = value;
      } else if (this[key] is Map<String, dynamic> && value is Map<String, dynamic>) {
        (this[key] as Map<String, dynamic>).addAllRecursive(value);
      } else {
        this[key] = value;
      }
    });
  }
}
