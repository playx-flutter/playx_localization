import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl_standalone.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/delegate/playx_localization_delegate.dart';
import 'package:playx_localization/src/easy_localization/translations.dart';

import '../easy_localization/localization.dart';
import 'translation_manager.dart';

const _lastKnownIndexKey = 'playx.locale.last_known_index';

/// PlayxLocalizationController :
/// Used to update current app locale with id, index, device locale and more.
/// And holds reference to the current app locale.
class PlayxLocaleController extends ValueNotifier<XLocale?> {
  final PlayxLocaleConfig config;

  PlayxLocaleController({
    required this.config,
  }) : super(null);

  /// The current PlayxLocaleController instance.
  static PlayxLocaleController? _localizationControllerInstance;

  /// The current PlayxLocaleController instance getter .
  /// Throws exception if not initialized.
  static PlayxLocaleController get controller {
    if (_localizationControllerInstance == null) {
      throw Exception(
          'PlayxLocalization has not been initialized. Please ensure you have called boot method before accessing any property.');
    }
    return _localizationControllerInstance!;
  }

  late PlayxLocalizationDelegate delegate;

  Translations? _translations, _fallbackTranslations;
  Map<Locale, Translations>? _preloadedTranslations;

  /// current translations loaded from assets.
  Translations? get translations => _translations;

  /// current fallback translations loaded from assets.
  Translations? get fallbackTranslations => _fallbackTranslations;

  /// all preloaded translations loaded from assets, if config.preloadSupportedLocales is true.
  Map<Locale, Translations>? get preloadedTranslations => _preloadedTranslations;

  // Returns the device locale.
  Locale? deviceLocale;

  static PlayxBaseLogger? get logger =>
      PlayxLogger.getLogger('Playx Localization');

  /// Whether the app locale is actively synced to the device locale
  bool get isDeviceLocaleSelected => _isDeviceLocaleSelected;
  bool _isDeviceLocaleSelected = false;

  /// current locale index
  int get currentIndex {
    if (value == null) {
      throw Exception(
          'Localization has not been initialized. You must call boot method before accessing any property.');
    }
    return config.supportedLocales.indexOf(value!);
  }

  /// set up the base controller to load locales.
  Future<void> boot() async {
    final logger = PlayxLogger.initLogger(
        name: 'Playx Localization',
        setAsDefault: false,
        useColoredFormatter: true);
    _localizationControllerInstance = this;
    final lastKnownIndex = await getLastSavedIndexFromPrefs(
        migratePrefsToAsync: config.migratePrefsToAsync);

    final foundPlatformLocale = await findSystemLocale();
    deviceLocale = foundPlatformLocale.toLocale();
    logger.i('Device Locale ${deviceLocale?.toStringWithSeparator()}');

    _isDeviceLocaleSelected = lastKnownIndex == -1;

    XLocale? lastSavedLocale;
    if (lastKnownIndex != null && lastKnownIndex >= 0) {
      lastSavedLocale = config.supportedLocales.atOrNull(lastKnownIndex);
    }

    final locale = _getStartLocale(savedLocale: lastSavedLocale);

    //Load translations from assets
    await loadTranslations(locale);
    logger.i('Loaded Translation from assets');

    delegate = PlayxLocalizationDelegate(
      localizationController: this,
      supportedLocales: supportedXLocales,
    );
    value = locale;

    logger.i(
        'Translation booted with locale ${locale.name} -> ${locale.toStringWithSeparator()} at index ${supportedXLocales.indexOf(locale)}');
  }

  /// Retrieves the last saved theme index from preferences.
  ///
  /// If [migratePrefsToAsync] is true, preferences are migrated to asynchronous storage.
  Future<int?> getLastSavedIndexFromPrefs({
    bool migratePrefsToAsync = false,
  }) async {
    await PlayxAsyncPrefs.create();
    int? lastSavedIndex = await PlayxAsyncPrefs.maybeGetInt(
      _lastKnownIndexKey,
    );
    if (migratePrefsToAsync && lastSavedIndex == null) {
      await PlayxPrefs.create();
      final lastKnownIndexInPrefs = PlayxPrefs.maybeGetInt(
        _lastKnownIndexKey,
      );
      logger?.i(
          'Migrating preferences to SharedPreferenceAsync found index $lastKnownIndexInPrefs');

      if (lastKnownIndexInPrefs != null) {
        await PlayxAsyncPrefs.setInt(_lastKnownIndexKey, lastKnownIndexInPrefs);
        lastSavedIndex = lastKnownIndexInPrefs;
      }
    }
    return lastSavedIndex;
  }

  ///Gets current locale to start the app with
  ///First return any saved locale
  ///If there isn't any save locale uses start locale from the config
  ///If there is no save locale, Then it uses device locale if it's supported in the config supported locales.
  ///If It's not supported then uses the first locale inf the config supported locales.
  XLocale _getStartLocale({XLocale? savedLocale}) {
    if (savedLocale != null) return savedLocale;

    if (!_isDeviceLocaleSelected && config.startLocale != null) return config.startLocale!;

    if (deviceLocale != null) {
      final searchedLocale = supportedXLocales.firstWhereOrNull(
          (e) => e.locale.supports(deviceLocale!));
      if (searchedLocale != null) {
        return searchedLocale;
      }

      final searchedLocaleByOnlyLanguageCode =
          supportedXLocales.firstWhereOrNull(
              (e) => e.languageCode == deviceLocale!.languageCode);
      if (searchedLocaleByOnlyLanguageCode != null) {
        return searchedLocaleByOnlyLanguageCode;
      }
    }
    return getFallbackLocale();
  }

  /// Get fallback Locale
  /// if fallbackLocale is not null then return it
  /// if fallbackLocale is null then return english locale if it's supported in the config supported locales.
  /// if english locale is not supported then return the first locale in the config supported locales.
  XLocale getFallbackLocale() {
    if (config.fallbackLocale != null) return config.fallbackLocale!;
    if (config.supportedLocales.any((e) => e.languageCode == 'en')) {
      return config.supportedLocales.firstWhere((e) => e.languageCode == 'en');
    }
    return config.supportedLocales.first;
  }

  /// Load translations from assets
  Future<void> loadTranslations(XLocale locale) async {
    final res = await TranslationManager.loadTranslations(
      locale: locale,
      config: config,
      fallbackLocale: getFallbackLocale(),
    );
    _translations = res.translations;
    _fallbackTranslations = res.fallbackTranslations;
    _preloadedTranslations = res.preloadedTranslations;

    Localization.load(
      locale.locale,
      translations: _translations,
      fallbackTranslations: _fallbackTranslations,
      preloadedTranslations: _preloadedTranslations,
      useFallbackTranslationsForEmptyResources:
          config.useFallbackTranslationsForEmptyResources,
      ignorePluralRules: config.ignorePluralRules,
    );
  }

  /// update the locale to be one of the supported locales.
  /// if the locale is not supported it will return false.
  /// if [forceAppUpdate] is true it will force the app to update.
  Future<bool> updateTo(XLocale locale, {bool forceAppUpdate = false}) async {
    final index = supportedXLocales.indexOf(locale);
    if (index < 0) {
      if (config.logLocaleChanges) {
        logger?.error('Locale not found in supported Locales');
      }
      return false;
    }
    return _updateLocale(
      locale: locale,
      forceAppUpdate: forceAppUpdate,
    );
  }

  /// switch the locale to the next in the supported locales list
  /// if there is no next locale, it will switch to the first one
  /// if [forceAppUpdate] is true it will force the app to update.
  Future<void> nextLocale({bool forceAppUpdate = false}) async {
    final isLastLocale = currentIndex == config.supportedLocales.length - 1;
    final index = isLastLocale ? 0 : currentIndex + 1;

    await updateByIndex(
      index,
      forceAppUpdate: forceAppUpdate,
    );
  }

  /// update the locale by index
  /// if the index is out of range it will return false.
  /// if [forceAppUpdate] is true it will force the app to update.
  Future<bool> updateByIndex(int index, {bool forceAppUpdate = false}) async {
    final locale = config.supportedLocales.atOrNull(index);
    if (locale == null) {
      if (config.logLocaleChanges) {
        logger
            ?.error('Locale with index $index not found in supported Locales');
      }
      return false;
    }
    return _updateLocale(locale: locale, forceAppUpdate: forceAppUpdate);
  }

  /// update the locale to by id
  /// if the id is not found it will return false.
  Future<bool> updateById(String id, {bool forceAppUpdate = false}) async {
    final locale =
        config.supportedLocales.firstWhereOrNull((element) => element.id == id);
    if (locale == null) {
      if (config.logLocaleChanges) {
        logger?.error('Locale with id $id not found in supported Locales');
      }
      return false;
    }
    return _updateLocale(locale: locale, forceAppUpdate: forceAppUpdate);
  }

  /// Search for locale by language code and country code if available.
  XLocale? searchLocaleByLanguageCode(
      {required String languageCode, String? countryCode, String? scriptCode}) {
    final searchLocale = Locale.fromSubtags(
        languageCode: languageCode,
        countryCode: countryCode,
        scriptCode: scriptCode);
    final searchedLocale = supportedXLocales.firstWhereOrNull(
        (e) => e.locale.supports(searchLocale));
    if (searchedLocale != null) {
      return searchedLocale;
    }
    //if not found then search by language code only.
    final searchedLocaleByOnlyLanguageCode = supportedXLocales
        .firstWhereOrNull((e) => e.languageCode == languageCode);
    if (searchedLocaleByOnlyLanguageCode != null) {
      return searchedLocaleByOnlyLanguageCode;
    }
    return null;
  }

  /// update the locale to by language code and country code if available.
  /// if the locale is not supported it will return false.
  /// if [forceAppUpdate] is true it will force the app to update.
  Future<bool> updateByLanguageCode(
      {required String languageCode,
      String? countryCode,
      String? scriptCode,
      bool forceAppUpdate = false}) async {
    final locale = searchLocaleByLanguageCode(
        languageCode: languageCode, countryCode: countryCode, scriptCode: scriptCode);
    if (locale != null) {
      return updateTo(
        locale,
        forceAppUpdate: forceAppUpdate,
      );
    }
    return false;
  }

  /// Updates the locale to current device locale.
  /// if the locale is not supported it will return false.
  /// if [forceAppUpdate] is true it will force the app to update.
  Future<bool> updateToDeviceLocale({bool forceAppUpdate = false}) async {
    final foundPlatformLocale = await findSystemLocale();
    final locale = foundPlatformLocale.toLocale();
    deviceLocale = locale;
    final search = searchLocaleByLanguageCode(
        languageCode: locale.languageCode,
        countryCode: locale.countryCode,
        scriptCode: locale.scriptCode);
    if (search != null) {
      return _updateLocale(
          locale: search, 
          forceAppUpdate: forceAppUpdate, 
          saveAsDeviceLocale: true);
    }
    return false;
  }

  /// Reset locale to platform locale or fallback locale.
  Future<void> resetLocale({bool forceAppUpdate = false}) async {
    final foundPlatformLocale = await findSystemLocale();
    deviceLocale = foundPlatformLocale.toLocale();
    final locale = _getStartLocale(savedLocale: null);

    logger?.i('Reset locale to ${locale.name} while the platform locale is $deviceLocale');
    await updateTo(locale, forceAppUpdate: forceAppUpdate);
  }

  /// Update the locale to be one of the supported locales.
  /// if [forceAppUpdate] is true it will force the app to update.
  Future<bool> _updateLocale({
    required XLocale locale,
    bool forceAppUpdate = false,
    bool saveAsDeviceLocale = false,
  }) async {
    try {
      final index = supportedXLocales.indexOf(locale);
      if (index < 0) {
        if (config.logLocaleChanges) {
          logger?.error('Locale not found in supported Locales');
        }
        return false;
      }

      await loadTranslations(
        locale,
      );
      if (config.saveLocale) {
        final savedIndex = saveAsDeviceLocale ? -1 : index;
        await PlayxAsyncPrefs.setInt(_lastKnownIndexKey, savedIndex);
      }
      _isDeviceLocaleSelected = saveAsDeviceLocale;
      
      final oldLocale = value;
      value = locale;

      if (forceAppUpdate) {
        await _forceAppUpdate();
      }

      if (config.logLocaleChanges) {
        logger?.i(
            'Updated locale to ${locale.name} with code ${locale.locale.toStringWithSeparator()} at index $index from ${oldLocale?.locale.toStringWithSeparator()}');
      }
      return true;
    } catch (e) {
      if (config.logLocaleChanges) {
        logger?.error(e);
      }
      return false;
    }
  }

  ///Force app update.
  Future<void> _forceAppUpdate() {
    return WidgetsFlutterBinding.ensureInitialized().performReassemble();
  }

  ///returns the current supported xLocales.
  List<XLocale> get supportedXLocales {
    return config.supportedLocales;
  }

  ///returns the current supported locales.
  List<Locale> get supportedLocales =>
      supportedXLocales.map((e) => e.locale).toList();

  ///Check if current locale is arabic.
  bool isCurrentLocaleArabic() {
    if (value == null) {
      throw Exception(
          'Localization has not been initialized. You must call boot method before accessing any property.');
    }
    return value!.languageCode == 'ar';
  }

  ///Check if current locale is english.
  bool isCurrentLocaleEnglish() {
    if (value == null) {
      throw Exception(
          'Localization has not been initialized. You must call boot method before accessing any property.');
    }
    return value!.languageCode == 'en';
  }

  ///Check if current locale is right to left.
  bool isCurrentLocaleRtl() {
    if (value == null) {
      throw Exception(
          'Localization has not been initialized. You must call boot method before accessing any property.');
    }
    return value!.locale.isRTL;
  }

  /// Convert current [locale] to String with custom [separator] representing language code and country code.
  String currentLocaleToString({String separator = '_'}) {
    if (value == null) {
      throw Exception(
          'Localization has not been initialized. You must call boot method before accessing any property.');
    }
    return value!.locale.toStringWithSeparator(separator: separator);
  }

  ///Reset saved locales.
  Future<void> deleteSavedLocale() async {
    return PlayxAsyncPrefs.remove(_lastKnownIndexKey);
  }

  //delegates to be used in material app.
  List<LocalizationsDelegate> get delegates =>
      config.customLocalizationDelegateBuilder?.call(delegate) ??
      [
        delegate,
        ...?config.extraDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];
}
