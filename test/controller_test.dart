import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/easy_localization/file_loaders/file_loader.dart';
import 'package:playx_localization/src/easy_localization/linked_file_resolver.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _NoFiles extends FileLoader {
  @override
  Future<String> loadString(String path) async => throw StateError(path);
}

/// Serves translations from memory, keyed by `Locale.toLanguageTag()`.
class MemoryAssetLoader extends AssetLoader {
  final Map<String, Map<String, dynamic>> data;

  MemoryAssetLoader(this.data)
      : super(
          fileLoader: _NoFiles(),
          linkedFileResolver: JsonLinkedFileResolver(fileLoader: _NoFiles()),
        );

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final d = data[locale.toLanguageTag()];
    if (d == null) throw FlutterError('No translations for $locale');
    return Map<String, dynamic>.from(d);
  }
}

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const zhHant = XLocale(
    id: 'zh_hant', name: 'Chinese T', languageCode: 'zh', scriptCode: 'Hant');
const zhHans = XLocale(
    id: 'zh_hans', name: 'Chinese S', languageCode: 'zh', scriptCode: 'Hans');

final translations = {
  'en': {
    'hello': 'Hello',
    'only_en': 'Only English',
    'greet': 'Hi {name}',
    'item': {'one': '{} item', 'other': '{} items'},
    'nested': {'a': 'A-en', 'b': 'B-en'},
  },
  'ar': {
    'hello': 'مرحبا',
    'nested': {'a': 'A-ar'},
  },
  'zh-Hant': {'hello': '哈囉'},
  'zh-Hans': {'hello': '你好'},
};

PlayxLocaleConfig makeConfig({
  List<AssetLoader>? extra,
  bool preload = false,
  XLocale? start,
}) =>
    PlayxLocaleConfig(
      supportedLocales: const [en, ar, zhHant, zhHans],
      startLocale: start,
      fallbackLocale: en,
      assetLoader: MemoryAssetLoader(translations),
      extraAssetLoaders: extra,
      preloadSupportedLocales: preload,
      logLocaleChanges: false,
    );

Future<PlayxLocaleController> boot(PlayxLocaleConfig config) async {
  final c = PlayxLocaleController(config: config);
  await c.boot();
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('boot', () {
    test('uses startLocale when nothing is saved', () async {
      final c = await boot(makeConfig(start: ar));
      expect(c.value, ar);
      expect(c.isDeviceLocaleSelected, isFalse);
    });

    test('restores saved locale over startLocale', () async {
      final first = await boot(makeConfig(start: en));
      await first.updateTo(ar);

      final second = await boot(makeConfig(start: en));
      expect(second.value, ar);
    });

    test('does not persist when saveLocale is false', () async {
      final config = PlayxLocaleConfig(
        supportedLocales: const [en, ar],
        startLocale: en,
        assetLoader: MemoryAssetLoader(translations),
        saveLocale: false,
        logLocaleChanges: false,
      );
      final first = await boot(config);
      await first.updateTo(ar);
      final second = await boot(config);
      expect(second.value, en);
    });
  });

  group('device locale sync', () {
    test('updateToDeviceLocale persists a device-sync flag (-1)', () async {
      final first = await boot(makeConfig(start: ar));
      expect(first.value, ar);

      final ok = await first.updateToDeviceLocale();
      // The test host locale is expected to be supported (en); skip otherwise.
      if (!ok) return;
      expect(first.isDeviceLocaleSelected, isTrue);

      // On the next boot the saved index is -1, so startLocale is ignored and
      // the device locale wins.
      final second = await boot(makeConfig(start: ar));
      expect(second.isDeviceLocaleSelected, isTrue);
      expect(second.value, first.value);
    });

    test('selecting an explicit locale clears the device-sync flag', () async {
      final c = await boot(makeConfig(start: en));
      await c.updateToDeviceLocale();
      await c.updateTo(ar);
      expect(c.isDeviceLocaleSelected, isFalse);

      final next = await boot(makeConfig(start: en));
      expect(next.value, ar);
      expect(next.isDeviceLocaleSelected, isFalse);
    });

    test('deleteSavedLocale forgets the saved choice', () async {
      final c = await boot(makeConfig(start: en));
      await c.updateTo(ar);
      await c.deleteSavedLocale();
      final next = await boot(makeConfig(start: en));
      expect(next.value, en);
    });
  });

  group('locale matching', () {
    late PlayxLocaleController c;
    setUp(() async => c = await boot(makeConfig(start: en)));

    test('matches script code', () {
      expect(
          c.searchLocaleByLanguageCode(languageCode: 'zh', scriptCode: 'Hant'),
          zhHant);
      expect(
          c.searchLocaleByLanguageCode(languageCode: 'zh', scriptCode: 'Hans'),
          zhHans);
    });

    test('falls back to language code only', () {
      expect(c.searchLocaleByLanguageCode(languageCode: 'ar', countryCode: 'EG'),
          ar);
      expect(c.searchLocaleByLanguageCode(languageCode: 'fr'), isNull);
    });

    test('updateByLanguageCode with script code', () async {
      expect(
          await c.updateByLanguageCode(languageCode: 'zh', scriptCode: 'Hans'),
          isTrue);
      expect(c.value, zhHans);
      expect('hello'.tr(), '你好');
    });

    test('update by id / index / unsupported', () async {
      expect(await c.updateById('ar'), isTrue);
      expect(c.value, ar);
      expect(await c.updateByIndex(0), isTrue);
      expect(c.value, en);
      expect(await c.updateById('nope'), isFalse);
      expect(await c.updateByIndex(99), isFalse);
      expect(await c.updateTo(const XLocale(id: 'x', name: 'x', languageCode: 'fr')),
          isFalse);
    });

    test('nextLocale wraps around', () async {
      await c.updateByIndex(3);
      await c.nextLocale();
      expect(c.value, en);
    });
  });

  group('translation loading', () {
    test('translates and falls back to fallback locale', () async {
      final c = await boot(makeConfig(start: ar));
      expect(c.value, ar);
      expect('hello'.tr(), 'مرحبا');
      expect('only_en'.tr(), 'Only English');
      expect('missing.key'.tr(), 'missing.key');
    });

    test('named args and plurals', () async {
      await boot(makeConfig(start: en));
      expect('greet'.tr(namedArgs: {'name': 'Sam'}), 'Hi Sam');
      expect('item'.plural(1), '1 item');
      expect('item'.plural(5), '5 items');
    });

    test('merges maps from extra loaders recursively', () async {
      final extra = MemoryAssetLoader({
        'en': {
          'hello': 'Hello (extra)',
          'nested': {'c': 'C-extra'},
        },
        'ar': {
          'nested': {'c': 'C-extra-ar'},
        },
      });
      final c = await boot(makeConfig(start: en, extra: [extra]));
      expect('hello'.tr(), 'Hello (extra)');
      expect('nested.a'.tr(), 'A-en');
      expect('nested.c'.tr(), 'C-extra');
      await c.updateTo(ar);
      expect('nested.a'.tr(), 'A-ar');
      expect('nested.c'.tr(), 'C-extra-ar');
    });

    test('preloadSupportedLocales allows synchronous any-locale lookup',
        () async {
      final c = await boot(makeConfig(start: en, preload: true));
      expect(c.preloadedTranslations, isNotNull);
      expect(c.preloadedTranslations!.length, 4);
      expect('hello'.tr(locale: const Locale('ar')), 'مرحبا');
      expect('hello'.tr(locale: const Locale('en')), 'Hello');
      expect(
          'hello'.tr(
              locale: const Locale.fromSubtags(
                  languageCode: 'zh', scriptCode: 'Hant')),
          '哈囉');
      // Current locale is untouched.
      expect(c.value, en);
    });

    test('without preload, other locales are not resolved', () async {
      await boot(makeConfig(start: en));
      expect('hello'.tr(locale: const Locale('ar')), 'hello');
    });
  });
}
