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
const fr = XLocale(id: 'fr', name: 'French', languageCode: 'fr');

final data = {
  'en': {
    'title': 'Title',
    'hello': 'Hello {name}',
    'item': {'one': '{} item', 'other': '{} items'},
  },
  'ar': {
    'title': 'عنوان',
    'hello': 'مرحبا {name}',
    'item': {'one': '{} عنصر', 'other': '{} عناصر'},
  },
  'fr': {'title': 'Titre'},
};

Future<PlayxLocaleController> boot({XLocale start = ar}) async {
  final c = PlayxLocaleController(
    config: PlayxLocaleConfig(
      supportedLocales: const [en, ar, fr],
      startLocale: start,
      fallbackLocale: en,
      assetLoader: MemoryAssetLoader(data),
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

  group('translate: false', () {
    test('returns the key as text', () async {
      await boot();
      expect('title'.tr(), 'عنوان');
      expect('title'.tr(translate: false), 'title');
      expect('Plain user text'.tr(translate: false), 'Plain user text');
    });

    test('still applies args and named args', () async {
      await boot();
      expect(
        'Hi {name}'.tr(translate: false, namedArgs: {'name': 'Sam'}),
        'Hi Sam',
      );
      expect('{} and {}'.tr(translate: false, args: ['a', 'b']), 'a and b');
    });

    test('does not look the key up, even if it exists', () async {
      await boot();
      expect('hello'.tr(translate: false, namedArgs: {'name': 'x'}), 'hello');
    });

    test('works for plural', () async {
      await boot();
      expect('item'.plural(3), '3 عناصر');
      expect('item'.plural(3, translate: false), 'item');
      expect('{} things'.plural(3, translate: false), '3 things');
      expect('{n} things'.plural(3, translate: false, name: 'n'), '3 things');
    });

    test('works for Text.tr', () async {
      await boot();
      expect(const Text('title').tr(translate: false).data, 'title');
      expect(const Text('title').tr().data, 'عنوان');
    });
  });

  group('per-call locale with preloadLocales', () {
    test('locale: is not available until preloaded', () async {
      await boot();
      expect('title'.tr(locale: const Locale('fr')), 'title');
    });

    test('preloaded locale can be used while the app uses another', () async {
      final c = await boot();
      await c.preloadLocales([const Locale('fr')]);
      expect('title'.tr(), 'عنوان');
      expect('title'.tr(locale: const Locale('fr')), 'Titre');
      expect(c.value, ar);
    });

    test('current and fallback locales work without preloading', () async {
      await boot();
      expect('title'.tr(locale: const Locale('ar')), 'عنوان');
      expect('title'.tr(locale: const Locale('en')), 'Title');
      expect('item'.plural(1, locale: const Locale('en')), '1 item');
    });

    test('preloaded locales survive locale changes', () async {
      final c = await boot();
      await c.preloadLocales([const Locale('fr')]);
      await c.updateTo(en);
      expect('title'.tr(), 'Title');
      expect('title'.tr(locale: const Locale('fr')), 'Titre');
      expect('title'.tr(locale: const Locale('ar')), 'title');
      await c.preloadLocales([const Locale('ar')]);
      expect('title'.tr(locale: const Locale('ar')), 'عنوان');
    });

    test('unsupported locales are ignored', () async {
      final c = await boot();
      await c.preloadLocales([const Locale('de')]);
      expect('title'.tr(locale: const Locale('de')), 'title');
      expect(c.preloadedTranslations, isNull);
    });
  });
}
