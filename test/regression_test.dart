import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart' hide TextDirection;
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/easy_localization/translation_source.dart';
import 'package:playx_localization/src/easy_localization/translations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const fr = XLocale(id: 'fr', name: 'French', languageCode: 'fr');

final data = {
  'en': {
    'title': 'Title',
    'group': {'child': 'Child'},
    'str': 'text',
    'link': 'See @:title',
    'link_upper': 'See @.upper:title',
    'empty': '',
    'link_empty': 'x @.capitalize:empty',
    'named': 'a {a.b} {x+y}',
    'only_en': 'Only English',
  },
  'ar': {'title': 'عنوان', 'link': 'انظر @:title'},
};

Future<PlayxLocaleController> boot({
  Map<String, Map<String, dynamic>>? files,
  bool useFallback = true,
  bool preload = false,
  List<XLocale> locales = const [en, ar],
  XLocale start = en,
}) async {
  final c = PlayxLocaleController(
    config: PlayxLocaleConfig(
      supportedLocales: locales,
      startLocale: start,
      fallbackLocale: en,
      useFallbackTranslations: useFallback,
      preloadSupportedLocales: preload,
      assetLoader: MemoryAssetLoader(files ?? data),
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

  group('Translations lookups', () {
    test('a key that points to a group does not crash', () async {
      await boot();
      expect('group'.tr(), 'group');
      expect('group.child'.tr(), 'Child');
    });

    test('a path through a string value is not found', () async {
      await boot();
      expect('str.child.more'.tr(), 'str.child.more');
      expect(Translations({'a': 'x'}).get('a.b.c'), isNull);
    });
  });

  group('config', () {
    test(
      'useFallbackTranslations: false disables the fallback locale',
      () async {
        final c = await boot(useFallback: false, start: ar);
        expect(c.fallbackTranslations, isNull);
        expect('only_en'.tr(), 'only_en');
      },
    );

    test('useFallbackTranslations: true uses the fallback locale', () async {
      await boot(start: ar);
      expect('only_en'.tr(), 'Only English');
    });
  });

  group('locale switching', () {
    test('a failed switch keeps the current locale and translations', () async {
      // fr is supported but has no translation file.
      final c = await boot(locales: const [en, ar, fr]);
      expect(await c.updateTo(fr), isFalse);
      expect(c.value, en);
      expect('title'.tr(), 'Title');
    });

    test('a failed switch is not saved', () async {
      final c = await boot(locales: const [en, ar, fr]);
      await c.updateTo(fr);
      final next = await boot(locales: const [en, ar, fr]);
      expect(next.value, en);
    });

    test('preload skips locales whose files are missing', () async {
      final c = await boot(locales: const [en, ar, fr], preload: true);
      expect(c.translations, isNotNull);
      expect(c.preloadedTranslations!.keys, contains(const Locale('ar')));
      expect('title'.tr(), 'Title');
    });
  });

  group('formatting', () {
    test('named args with regex characters in the name', () async {
      await boot();
      expect('named'.tr(namedArgs: {'a.b': '1', 'x+y': '2'}), 'a 1 2');
    });

    test('links are resolved in the requested locale', () async {
      await boot(preload: true);
      expect('link'.tr(), 'See Title');
      expect('link'.tr(locale: const Locale('ar')), 'انظر عنوان');
    });

    test('capitalize modifier on an empty value does not crash', () async {
      await boot();
      expect('link_empty'.tr(), isA<String>());
      expect('link_upper'.tr(), 'See TITLE');
    });
  });

  group('widgets and facade', () {
    test('Text.tr keeps the original Text locale', () async {
      await boot();
      final t = const Text('title', locale: Locale('fr')).tr();
      expect(t.locale, const Locale('fr'));
    });

    testWidgets('context RTL helpers use the language, not the text', (
      tester,
    ) async {
      late BuildContext arabic, english;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              PlayxInheritedLocalization(
                locale: ar,
                child: Builder(
                  builder: (c) {
                    arabic = c;
                    return const SizedBox();
                  },
                ),
              ),
              PlayxInheritedLocalization(
                locale: en,
                child: Builder(
                  builder: (c) {
                    english = c;
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      );
      expect(arabic.isCurrentLocaleRtl, isTrue);
      expect(arabic.isCurrentLocaleLtr, isFalse);
      expect(english.isCurrentLocaleRtl, isFalse);
      expect(english.isCurrentLocaleLtr, isTrue);
    });

    test('facade updateByLanguageCode accepts scriptCode and '
        'currentLocaleToString is callable', () async {
      await boot();
      expect(
        await PlayxLocalization.updateByLanguageCode(
          languageCode: 'ar',
          scriptCode: null,
        ),
        isTrue,
      );
      expect(PlayxLocalization.currentLocaleToString(), 'ar');
    });
  });
}
