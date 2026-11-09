import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/easy_localization/plural_rules.dart';
import 'package:playx_localization/src/tools/translation_validator.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const ru = XLocale(id: 'ru', name: 'Russian', languageCode: 'ru');

final data = {
  'en': {
    'vehicle': {'one': 'vehicle', 'two': 'two vehicles', 'other': '{} vehicles'},
    'item': {'zero': 'no items', 'one': 'one item', 'other': '{} items'},
  },
  'ar': {
    'vehicle': {
      'one': 'مركبة',
      'two': 'مركبتان',
      'few': '{} مركبات',
      'many': '{} مركبة',
      'other': '{} مركبة',
    },
    'only_other': {'other': '{} عنصر'},
  },
  'ru': {
    'day': {'one': '{} день', 'few': '{} дня', 'many': '{} дней', 'other': '{} дня'},
  },
};

Future<void> boot({
  XLocale start = ar,
  bool? ignore,
  bool? digits,
}) async {
  final c = PlayxLocaleController(
    config: PlayxLocaleConfig(
      supportedLocales: const [en, ar, ru],
      startLocale: start,
      fallbackLocale: en,
      ignorePluralRules: ignore ?? false,
      localizePluralDigits: digits ?? false,
      assetLoader: MemoryAssetLoader(data),
      storage: PlayxMemoryLocaleStorage(),
      logLocaleChanges: false,
    ),
  );
  await c.boot();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Arabic nouns with numbers (default config)', () {
    test('1, 2, 3-10, 11-99 and 100+', () async {
      await boot();
      expect('vehicle'.plural(1), 'مركبة');
      expect('vehicle'.plural(2), 'مركبتان');
      expect('vehicle'.plural(3), '3 مركبات');
      expect('vehicle'.plural(10), '10 مركبات');
      expect('vehicle'.plural(11), '11 مركبة');
      expect('vehicle'.plural(99), '99 مركبة');
      expect('vehicle'.plural(100), '100 مركبة');
      expect('vehicle'.plural(103), '103 مركبات');
    });

    test('zero falls back to other when there is no zero form', () async {
      await boot();
      expect('vehicle'.plural(0), '0 مركبة');
    });

    test('localizeDigits per call shows Arabic digits', () async {
      await boot();
      expect('vehicle'.plural(3, localizeDigits: true), '٣ مركبات');
      expect('vehicle'.plural(11, localizeDigits: true), '١١ مركبة');
      expect('vehicle'.plural(1, localizeDigits: true), 'مركبة');
      expect('vehicle'.plural(2, localizeDigits: true), 'مركبتان');
      expect('vehicle'.plural(1250, localizeDigits: true), '١٬٢٥٠ مركبة');
    });

    test('localizePluralDigits in the config applies everywhere', () async {
      await boot(digits: true);
      expect('vehicle'.plural(3), '٣ مركبات');
      expect('vehicle'.plural(11), '١١ مركبة');
      // And can be turned off for a single call.
      expect('vehicle'.plural(3, localizeDigits: false), '3 مركبات');
    });

    test('a custom format still wins over localized digits', () async {
      await boot(digits: true);
      expect(
          'vehicle'.plural(3, format: NumberFormat('000', 'en')), '003 مركبات');
    });

    test('a group with only "other" works for every number', () async {
      await boot();
      expect('only_other'.plural(1), '1 عنصر');
      expect('only_other'.plural(5), '5 عنصر');
    });

    test('Text.plural and name arguments use the same rules', () async {
      await boot();
      expect(const Text('vehicle').plural(3, localizeDigits: true).data,
          '٣ مركبات');
    });
  });

  group('other languages', () {
    test('an explicit zero/one/two form wins for 0, 1 and 2', () async {
      await boot(start: en);
      expect('item'.plural(0), 'no items');
      expect('item'.plural(1), 'one item');
      expect('item'.plural(2), '2 items');
      expect('vehicle'.plural(2), 'two vehicles');
      expect('vehicle'.plural(1), 'vehicle');
    });

    test('English decimals are not singular', () async {
      await boot(start: en);
      expect('item'.plural(1.5), '1.5 items');
      expect('item'.plural(1.4), '1.4 items');
    });

    test('Russian uses its rules', () async {
      await boot(start: ru);
      expect('day'.plural(1), '1 день');
      expect('day'.plural(3), '3 дня');
      expect('day'.plural(11), '11 дней');
      expect('day'.plural(21), '21 день');
    });

    test('digits are localized for the requested locale', () async {
      await boot(start: en);
      await PlayxLocalization.preloadLocales([const Locale('ar')]);
      expect(
          'vehicle'.plural(3, locale: const Locale('ar'), localizeDigits: true),
          '٣ مركبات');
    });
  });

  group('ignorePluralRules: true keeps the simple behavior', () {
    test('only zero, one, two and other are used', () async {
      await boot(ignore: true);
      expect('vehicle'.plural(1), 'مركبة');
      expect('vehicle'.plural(2), 'مركبتان');
      expect('vehicle'.plural(3), '3 مركبة');
      expect('vehicle'.plural(11), '11 مركبة');
    });
  });

  group('pluralCategoriesFor', () {
    Set<String> names(String lang) =>
        pluralCategoriesFor(lang).map((c) => c.name.toLowerCase()).toSet();

    test('known languages', () {
      expect(names('ar'), {'zero', 'one', 'two', 'few', 'many', 'other'});
      expect(names('en'), {'one', 'other'});
      expect(names('ru'), {'one', 'few', 'many', 'other'});
      expect(names('ja'), {'other'});
      expect(names('xx'), {'other'});
    });
  });

  group('validator warns about missing plural forms', () {
    test('Arabic group without few/many', () {
      final issues = validateTranslations(baseLocale: 'en', locales: {
        'en': {
          'v': {'one': 'a', 'other': 'b'}
        },
        'ar': {
          'v': {'one': 'a', 'two': 'b', 'other': 'c'},
        },
      });
      expect(
        issues.map((i) => i.toString()),
        contains(contains('[ar] v: plural group has no few, many form')),
      );
    });

    test('complete Arabic group and English one/other are fine', () {
      final issues = validateTranslations(baseLocale: 'en', locales: {
        'en': {
          'v': {'one': 'a', 'other': 'b'}
        },
        'ar': {
          'v': {
            'one': 'a',
            'two': 'b',
            'few': 'c',
            'many': 'd',
            'other': 'e',
          },
        },
      });
      expect(issues, isEmpty);
    });

    test('regional file names use the language', () {
      final issues = validateTranslations(baseLocale: 'en', locales: {
        'en': {
          'v': {'one': 'a', 'other': 'b'}
        },
        'ar-EG': {
          'v': {'one': 'a', 'other': 'b'},
        },
      });
      expect(issues.single.toString(), contains('few, many, two'));
    });
  });
}
