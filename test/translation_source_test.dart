import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/easy_localization/translation_source.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const enUS = XLocale(
  id: 'en_us',
  name: 'English US',
  languageCode: 'en',
  countryCode: 'US',
);

final appData = {
  'en': {'app': 'App', 'shared': 'from app'},
  'ar': {'app': 'تطبيق'},
};

PlayxTranslationSource pkgSource(
  String id,
  Map<String, Map<String, dynamic>> data, {
  String? namespace,
}) => PlayxTranslationSource(
  id: id,
  path: 'packages/$id',
  namespace: namespace,
  loader: MemoryAssetLoader(data),
);

Future<PlayxLocaleController> boot({
  List<XLocale>? locales,
  XLocale? start,
}) async {
  final c = PlayxLocaleController(
    config: PlayxLocaleConfig(
      supportedLocales: locales ?? const [en, ar],
      startLocale: start ?? en,
      fallbackLocale: en,
      assetLoader: MemoryAssetLoader(appData),
      logLocaleChanges: false,
    ),
  );
  await c.boot();
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    TranslationSourceRegistry.clear();
  });

  test('source registered before boot is merged', () async {
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'pkg_title': 'Package'},
      }),
    );
    await boot();
    expect('pkg_title'.tr(), 'Package');
    expect('app'.tr(), 'App');
  });

  test('source registered after boot reloads and notifies', () async {
    final c = await boot();
    var notified = 0;
    c.addListener(() => notified++);
    expect('pkg_title'.tr(), 'pkg_title');

    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'pkg_title': 'Package'},
      }),
    );
    expect('pkg_title'.tr(), 'Package');
    expect(notified, 1);
  });

  test('app translations override source translations', () async {
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'shared': 'from package', 'only_pkg': 'x'},
      }),
    );
    await boot();
    expect('shared'.tr(), 'from app');
    expect('only_pkg'.tr(), 'x');
  });

  test('later registered source wins over earlier one', () async {
    await PlayxLocalization.registerTranslations(
      pkgSource('a', {
        'en': {'k': 'a'},
      }),
    );
    await PlayxLocalization.registerTranslations(
      pkgSource('b', {
        'en': {'k': 'b'},
      }),
    );
    await boot();
    expect('k'.tr(), 'b');
  });

  test('namespace prefixes keys, including dotted namespaces', () async {
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {
          'title': 'Hi',
          'sub': {'x': 'X'},
        },
      }, namespace: 'pkg_a'),
    );
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_b', {
        'en': {'title': 'Hello'},
      }, namespace: 'libs.pkg_b'),
    );
    await boot();
    expect('pkg_a.title'.tr(), 'Hi');
    expect('pkg_a.sub.x'.tr(), 'X');
    expect('libs.pkg_b.title'.tr(), 'Hello');
    expect('title'.tr(), 'title');
  });

  test('source missing a locale is skipped and does not break loading', () async {
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'pkg_title': 'Package'},
      }),
    );
    final c = await boot();
    expect(await c.updateTo(ar), isTrue);
    expect('app'.tr(), 'تطبيق');
    // Falls back to the fallback locale's translations, which include the source.
    expect('pkg_title'.tr(), 'Package');
  });

  test('regional locale falls back to the language file', () async {
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'pkg_title': 'Package'},
      }),
    );
    final c = PlayxLocaleController(
      config: PlayxLocaleConfig(
        supportedLocales: const [enUS],
        startLocale: enUS,
        assetLoader: MemoryAssetLoader({
          'en-US': {'app': 'App US'},
        }),
        logLocaleChanges: false,
      ),
    );
    await c.boot();
    expect('pkg_title'.tr(), 'Package');
    expect('app'.tr(), 'App US');
  });

  test('re-registering the same id replaces the source', () async {
    await boot();
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'k': 'one'},
      }),
    );
    expect('k'.tr(), 'one');
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'k': 'two'},
      }),
    );
    expect('k'.tr(), 'two');
    expect(TranslationSourceRegistry.sources.length, 1);
  });

  test('unregister removes the translations', () async {
    await boot();
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'k': 'one'},
      }),
    );
    expect(await PlayxLocalization.unregisterTranslations('pkg_a'), isTrue);
    expect('k'.tr(), 'k');
    expect(await PlayxLocalization.unregisterTranslations('pkg_a'), isFalse);
  });

  test('PlayxTranslationSource.package builds the package asset path', () {
    final s = PlayxTranslationSource.package(package: 'my_pkg');
    expect(s.id, 'my_pkg');
    expect(s.path, 'packages/my_pkg/assets/translations');
    expect(
      PlayxTranslationSource.package(package: 'p', path: '/i18n').path,
      'packages/p/i18n',
    );
  });

  test('preloaded locales include source translations', () async {
    await PlayxLocalization.registerTranslations(
      pkgSource('pkg_a', {
        'en': {'pkg_title': 'Package'},
        'ar': {'pkg_title': 'حزمة'},
      }),
    );
    final c = PlayxLocaleController(
      config: PlayxLocaleConfig(
        supportedLocales: const [en, ar],
        startLocale: en,
        assetLoader: MemoryAssetLoader(appData),
        preloadSupportedLocales: true,
        logLocaleChanges: false,
      ),
    );
    await c.boot();
    expect('pkg_title'.tr(locale: const Locale('ar')), 'حزمة');
  });
}
