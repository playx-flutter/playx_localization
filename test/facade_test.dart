import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const fr = XLocale(id: 'fr', name: 'French', languageCode: 'fr');

final data = {
  'en': {'k': 'English'},
  'ar': {'k': 'عربي'},
  'fr': {'k': 'Français'},
};

Future<void> boot({
  XLocale start = en,
  bool useFallback = true,
  PlayxLocaleStorage? storage,
}) =>
    PlayxLocalization.boot(
      config: PlayxLocaleConfig(
        supportedLocales: const [en, ar, fr],
        startLocale: start,
        fallbackLocale: en,
        useFallbackTranslations: useFallback,
        assetLoader: MemoryAssetLoader(data),
        storage: storage ?? PlayxMemoryLocaleStorage(),
        logLocaleChanges: false,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getters expose the booted state', () async {
    await boot(start: ar);
    expect(PlayxLocalization.supportedXLocales, const [en, ar, fr]);
    expect(PlayxLocalization.supportedLocales,
        const [Locale('en'), Locale('ar'), Locale('fr')]);
    expect(PlayxLocalization.currentIndex, 1);
    expect(PlayxLocalization.currentXLocale, ar);
    expect(PlayxLocalization.currentLocale, const Locale('ar'));
    expect(PlayxLocalization.deviceLocale, isNotNull);
    expect(PlayxLocalization.isDeviceLocaleSelected, isFalse);
    expect(PlayxLocalization.fallbackLocale, en);
    expect(PlayxLocalization.isCurrentLocaleArabic(), isTrue);
    expect(PlayxLocalization.isCurrentLocaleEnglish(), isFalse);
    expect(PlayxLocalization.isCurrentLocaleRtl(), isTrue);
    expect(PlayxLocalization.currentLocaleToString(), 'ar');
    expect(PlayxLocalization.currentLocaleToString(separator: '-'), 'ar');
  });

  test('fallbackLocale is null when fallback translations are disabled',
      () async {
    await boot(useFallback: false);
    expect(PlayxLocalization.fallbackLocale, isNull);
  });

  test('update methods', () async {
    await boot();
    expect(await PlayxLocalization.updateTo(ar), isTrue);
    expect('k'.tr(), 'عربي');
    expect(await PlayxLocalization.updateByIndex(2), isTrue);
    expect('k'.tr(), 'Français');
    expect(await PlayxLocalization.updateById('en'), isTrue);
    expect('k'.tr(), 'English');
    expect(
        await PlayxLocalization.updateByLanguageCode(languageCode: 'fr'), isTrue);
    expect(PlayxLocalization.currentXLocale, fr);
    expect(await PlayxLocalization.updateByIndex(9), isFalse);
    expect(await PlayxLocalization.updateById('zz'), isFalse);
    expect(
        await PlayxLocalization.updateByLanguageCode(languageCode: 'de'),
        isFalse);
    expect(PlayxLocalization.currentXLocale, fr);
  });

  test('nextLocale cycles through the supported locales', () async {
    await boot();
    await PlayxLocalization.nextLocale();
    expect(PlayxLocalization.currentXLocale, ar);
    await PlayxLocalization.nextLocale();
    await PlayxLocalization.nextLocale();
    expect(PlayxLocalization.currentXLocale, en);
  });

  test('updateToDeviceLocale follows the device', () async {
    await boot(start: ar);
    final ok = await PlayxLocalization.updateToDeviceLocale();
    if (ok) {
      expect(PlayxLocalization.isDeviceLocaleSelected, isTrue);
      expect(PlayxLocalization.currentLocale.languageCode,
          PlayxLocalization.deviceLocale!.languageCode);
    }
  });

  test('resetLocale restores the start locale', () async {
    await boot();
    await PlayxLocalization.updateTo(fr);
    await PlayxLocalization.resetLocale();
    expect(PlayxLocalization.currentXLocale, en);
  });

  test('deleteSavedLocale forgets the choice for the next boot', () async {
    final storage = PlayxMemoryLocaleStorage();
    await boot(storage: storage);
    await PlayxLocalization.updateTo(ar);
    await PlayxLocalization.deleteSavedLocale();
    await boot(storage: storage);
    expect(PlayxLocalization.currentXLocale, en);
  });

  test('preloadLocales and delegates', () async {
    await boot();
    await PlayxLocalization.preloadLocales([const Locale('fr')]);
    expect('k'.tr(locale: const Locale('fr')), 'Français');
    expect(PlayxLocalization.localizationDelegates, isNotEmpty);
  });
}
