import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart' hide TextDirection;
import 'package:playx_localization/src/controller/controller.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const fr = XLocale(id: 'fr', name: 'French', languageCode: 'fr');
const zhHant = XLocale(
  id: 'zh_hant',
  name: 'Chinese T',
  languageCode: 'zh',
  scriptCode: 'Hant',
);

final data = {
  'en': {'k': 'English'},
  'ar': {'k': 'عربي'},
  'fr': {'k': 'Français'},
  'zh-Hant': {'k': '繁體'},
};

PlayxLocaleConfig cfg({
  List<XLocale> locales = const [en, ar],
  XLocale? start,
  bool logChanges = true,
  List<LocalizationsDelegate>? extra,
  List<LocalizationsDelegate> Function(PlayxLocalizationDelegate)? builder,
  bool useOnlyLangCode = false,
  Map<String, Map<String, dynamic>>? files,
}) => PlayxLocaleConfig(
  supportedLocales: locales,
  startLocale: start,
  assetLoader: MemoryAssetLoader(files ?? data),
  storage: PlayxMemoryLocaleStorage(),
  logLocaleChanges: logChanges,
  extraDelegates: extra,
  customLocalizationDelegateBuilder: builder,
  useOnlyLangCode: useOnlyLangCode,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('before boot', () {
    test('getters throw until the controller has a locale', () {
      final c = PlayxLocaleController(config: cfg());
      expect(() => c.currentIndex, throwsException);
      expect(c.isCurrentLocaleArabic, throwsException);
      expect(c.isCurrentLocaleEnglish, throwsException);
      expect(c.isCurrentLocaleRtl, throwsException);
      expect(c.currentLocaleToString, throwsException);
      expect(c.value, isNull);
    });

    test('reloadTranslations does nothing without a locale', () async {
      final c = PlayxLocaleController(config: cfg());
      await c.reloadTranslations();
      expect(c.translations, isNull);
    });
  });

  group('with logging enabled', () {
    test('failed updates return false and log', () async {
      final c = PlayxLocaleController(config: cfg(start: en));
      await c.boot();
      expect(await c.updateTo(fr), isFalse);
      expect(await c.updateById('zz'), isFalse);
      expect(await c.updateByIndex(9), isFalse);
      expect(c.value, en);
    });

    test('a locale without a translation file keeps the current one', () async {
      final c = PlayxLocaleController(
        config: cfg(
          locales: const [en, ar, fr],
          start: en,
          files: {
            'en': {'k': 'English'},
            'ar': {'k': 'عربي'},
          },
        ),
      );
      await c.boot();
      expect(await c.updateTo(fr), isFalse);
      expect(c.value, en);
    });

    test('successful updates, next locale and reset', () async {
      final c = PlayxLocaleController(config: cfg(start: en));
      await c.boot();
      expect(await c.updateTo(ar), isTrue);
      expect(c.currentIndex, 1);
      expect(c.isCurrentLocaleArabic(), isTrue);
      expect(c.isCurrentLocaleEnglish(), isFalse);
      expect(c.isCurrentLocaleRtl(), isTrue);
      expect(c.currentLocaleToString(), 'ar');
      await c.nextLocale();
      expect(c.value, en);
      expect(c.isCurrentLocaleEnglish(), isTrue);
      expect(c.isCurrentLocaleRtl(), isFalse);
      await c.updateTo(ar);
      await c.resetLocale();
      expect(c.value, en);
    });
  });

  group('forceAppUpdate', () {
    testWidgets('reassembles the app', (tester) async {
      final c = PlayxLocaleController(config: cfg(start: en));
      await c.boot();
      await tester.pumpWidget(const SizedBox());
      final result = c.updateTo(ar, forceAppUpdate: true);
      // The reassemble waits for a frame.
      await tester.pumpAndSettle();
      expect(await result, isTrue);
      expect(c.value, ar);
    });
  });

  group('device locale', () {
    test('fails when the device language is not supported', () async {
      final c = PlayxLocaleController(
        config: cfg(locales: const [ar, fr], start: ar),
      );
      await c.boot();
      // The test host reports an en-US device locale.
      expect(await c.updateToDeviceLocale(), isFalse);
      expect(c.isDeviceLocaleSelected, isFalse);
    });

    test('succeeds when it is supported and boot then follows it', () async {
      final config = cfg(start: ar);
      final c = PlayxLocaleController(config: config);
      await c.boot();
      expect(await c.updateToDeviceLocale(), isTrue);
      expect(c.value, en);
      expect(c.isDeviceLocaleSelected, isTrue);
    });
  });

  group('delegates', () {
    test('default list has the package and Flutter delegates', () async {
      final c = PlayxLocaleController(config: cfg(start: en));
      await c.boot();
      expect(c.delegates.first, c.delegate);
      expect(c.delegates, contains(GlobalMaterialLocalizations.delegate));
      expect(c.delegates, contains(GlobalWidgetsLocalizations.delegate));
      expect(c.delegates, contains(GlobalCupertinoLocalizations.delegate));
    });

    test('extra delegates are added', () async {
      final extra = DefaultMaterialLocalizations.delegate;
      final c = PlayxLocaleController(
        config: cfg(start: en, extra: [extra]),
      );
      await c.boot();
      expect(c.delegates, contains(extra));
    });

    test('a custom builder replaces the list', () async {
      final c = PlayxLocaleController(
        config: cfg(start: en, builder: (d) => [d]),
      );
      await c.boot();
      expect(c.delegates, [c.delegate]);
    });
  });

  group('locale details', () {
    test(
      'useOnlyLangCode loads the language file for regional locales',
      () async {
        const enUS = XLocale(
          id: 'en_us',
          name: 'English US',
          languageCode: 'en',
          countryCode: 'US',
        );
        final c = PlayxLocaleController(
          config: cfg(
            locales: const [enUS],
            start: enUS,
            useOnlyLangCode: true,
            files: {
              'en': {'k': 'language only'},
            },
          ),
        );
        await c.boot();
        expect('k'.tr(), 'language only');
      },
    );

    test('script code locales load and are found by script', () async {
      final c = PlayxLocaleController(
        config: cfg(locales: const [en, zhHant], start: zhHant),
      );
      await c.boot();
      expect('k'.tr(), '繁體');
      expect(
        c.supportedLocales.last,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
      expect(c.currentLocaleToString(separator: '-'), 'zh-Hant');
    });

    test('searchLocaleByLanguageCode falls back to the language', () async {
      final c = PlayxLocaleController(config: cfg());
      expect(
        c.searchLocaleByLanguageCode(languageCode: 'ar', countryCode: 'EG'),
        ar,
      );
      expect(c.searchLocaleByLanguageCode(languageCode: 'de'), isNull);
    });

    test('getFallbackLocale prefers english, then the first locale', () {
      expect(PlayxLocaleController(config: cfg()).getFallbackLocale(), en);
      expect(
        PlayxLocaleController(
          config: cfg(locales: const [ar, fr]),
        ).getFallbackLocale(),
        ar,
      );
    });

    test(
      'deprecated getLastSavedIndexFromPrefs reads the saved index',
      () async {
        final c = PlayxLocaleController(config: cfg(start: en));
        await c.boot();
        await c.updateTo(ar);
        // ignore: deprecated_member_use_from_same_package
        expect(await c.getLastSavedIndexFromPrefs(), 1);
      },
    );
  });
}
