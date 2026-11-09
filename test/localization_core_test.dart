import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/easy_localization/localization.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const ru = XLocale(id: 'ru', name: 'Russian', languageCode: 'ru');

final data = {
  'en': {
    'name': 'john',
    'hello': 'Hello',
    'gender': {'male': 'Hi man {}', 'female': 'Hi girl {}', 'other': 'Hi {}'},
    'up': 'Say @.upper:hello',
    'low': 'Say @.lower:hello',
    'cap': 'Say @.capitalize:name',
    'bad_mod': 'Say @.nope:hello',
    'paren': 'Say @:(hello)!',
    'missing_link': 'Say @:does_not_exist',
    'empty_in_ar_only': 'English text',
    'only_en': 'Only English',
    'numbers': {'one': '{} thing', 'other': '{} things'},
    'named_plural': {'one': '{n} apple', 'other': '{n} apples'},
    'no_other': {'one': 'one only'},
    'zero_plural': {
      'zero': 'none',
      'one': 'one',
      'two': 'two',
      'other': 'many {}',
    },
  },
  'ar': {
    'hello': 'مرحبا',
    'empty_in_ar_only': '',
    'day': {
      'zero': 'صفر {}',
      'one': 'يوم {}',
      'two': 'يومان {}',
      'few': 'أيام قليلة {}',
      'many': 'أيام كثيرة {}',
      'other': 'أيام {}',
    },
  },
  'ru': {
    'day': {
      'one': '{} день',
      'few': '{} дня',
      'many': '{} дней',
      'other': '{} дня',
    },
  },
};

Future<PlayxLocaleController> boot({
  XLocale start = en,
  bool ignorePluralRules = true,
  bool emptyFallback = false,
  bool logMissing = false,
}) async {
  final c = PlayxLocaleController(
    config: PlayxLocaleConfig(
      supportedLocales: const [en, ar, ru],
      startLocale: start,
      fallbackLocale: en,
      ignorePluralRules: ignorePluralRules,
      useFallbackTranslationsForEmptyResources: emptyFallback,
      logMissingKeys: logMissing,
      assetLoader: MemoryAssetLoader(data),
      storage: PlayxMemoryLocaleStorage(),
      logLocaleChanges: false,
    ),
  );
  await c.boot();
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('gender', () {
    test('picks the gender form', () async {
      await boot();
      expect('gender'.tr(gender: 'male', args: ['Sam']), 'Hi man Sam');
      expect('gender'.tr(gender: 'female', args: ['Sam']), 'Hi girl Sam');
      expect('gender'.tr(gender: 'other', args: ['Sam']), 'Hi Sam');
    });
  });

  group('links and modifiers', () {
    test('modifiers and plain links', () async {
      await boot();
      expect('up'.tr(), 'Say HELLO');
      expect('low'.tr(), 'Say hello');
      expect('cap'.tr(), 'Say John');
      expect('paren'.tr(), 'Say Hello!');
    });

    test('unknown modifier and missing link keep the text readable', () async {
      await boot(logMissing: true);
      expect('bad_mod'.tr(), 'Say Hello');
      expect('missing_link'.tr(), contains('Say'));
    });
  });

  group('lookup and fallback', () {
    test('exists only checks the current locale', () async {
      await boot(start: ar);
      expect(Localization.instance.exists('hello'), isTrue);
      expect(Localization.instance.exists('only_en'), isFalse);
    });

    test('missing keys are returned (with logging on)', () async {
      await boot(logMissing: true);
      expect('nope.nope'.tr(), 'nope.nope');
    });

    test('empty values fall back when enabled', () async {
      await boot(start: ar, emptyFallback: true);
      expect('empty_in_ar_only'.tr(), 'English text');
    });

    test('empty values are kept when fallback for empty is disabled', () async {
      await boot(start: ar);
      expect('empty_in_ar_only'.tr(), '');
    });

    test('key missing everywhere with empty fallback enabled', () async {
      await boot(start: ar, emptyFallback: true, logMissing: true);
      expect('nowhere'.tr(), 'nowhere');
    });
  });

  group('plural with simple rules (default)', () {
    test('zero, one, two and other', () async {
      await boot();
      expect('zero_plural'.plural(0), 'none');
      expect('zero_plural'.plural(1), 'one');
      expect('zero_plural'.plural(2), 'two');
      expect('zero_plural'.plural(7), 'many 7');
    });

    test('falls back to other when a form is missing', () async {
      await boot();
      expect('numbers'.plural(0), '0 things');
      expect('numbers'.plural(5), '5 things');
    });

    test('name, format and args', () async {
      await boot();
      expect('named_plural'.plural(1, name: 'n'), '1 apple');
      expect('named_plural'.plural(3, name: 'n'), '3 apples');
      expect(
        'numbers'.plural(1000, format: NumberFormat.decimalPattern('en')),
        '1,000 things',
      );
      expect('named_plural'.plural(2, namedArgs: {'n': 'two'}), 'two apples');
      expect('zero_plural'.plural(5, args: ['five']), 'many five');
    });
  });

  group('plural with language rules', () {
    test('Arabic uses its six forms', () async {
      await boot(start: ar, ignorePluralRules: false);
      expect('day'.plural(0), 'صفر 0');
      expect('day'.plural(1), 'يوم 1');
      expect('day'.plural(2), 'يومان 2');
      expect('day'.plural(5), 'أيام قليلة 5');
      expect('day'.plural(20), 'أيام كثيرة 20');
      expect('day'.plural(100), 'أيام 100');
    });

    test('Russian uses one, few and many', () async {
      await boot(start: ru, ignorePluralRules: false);
      expect('day'.plural(1), '1 день');
      expect('day'.plural(3), '3 дня');
      expect('day'.plural(11), '11 дней');
      expect('day'.plural(21), '21 день');
    });

    test('a locale without rules uses the simple fallback', () async {
      await boot(ignorePluralRules: false);
      expect('numbers'.plural(1), '1 thing');
    });
  });
}
