import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';

void main() {
  group('String extensions', () {
    test('rtl / ltr detection', () {
      expect('مرحبا'.isRtl, isTrue);
      expect('hello'.isLtr, isTrue);
    });

    test('language detection', () {
      expect('abc'.isEnglish, isTrue);
      expect('مرحبا'.isArabic, isTrue);
      expect('مرحبا بك'.containsOnlyArabic, isTrue);
      expect('مرحبا 1'.containsOnlyArabic, isFalse);
      expect('hello world'.containsOnlyEnglish, isTrue);
      expect('hello1'.containsOnlyEnglish, isFalse);
      expect('a1'.hasNumbers, isTrue);
      expect('ab'.hasNumbers, isFalse);
    });

    test('digit conversion', () {
      expect('0123456789'.toArabicIndicDigits(), '٠١٢٣٤٥٦٧٨٩');
      expect('٠١٢٣٤٥٦٧٨٩'.toEnglishDigits(), '0123456789');
      expect('12'.toLocalizedDigits(locale: 'ar'), '١٢');
      expect('12'.toLocalizedDigits(locale: 'ar', toArabic: false), '12');
      expect('١٢'.toLocalizedDigits(locale: 'en'), '12');
    });

    test('arabic text utilities', () {
      expect('مُحَمَّد'.stripDiacritics, 'محمد');
      expect('أحمد إبراهيم آمنة'.normalizeArabicLetters(), 'احمد ابراهيم امنه');
      expect('  a   b \n c '.removeExtraSpaces(), 'a b c');
    });

    test('toLocale', () {
      expect('en'.toLocale(), const Locale('en'));
      expect('en_US'.toLocale(), const Locale('en', 'US'));
      expect(
        'zh_Hant'.toLocale(),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
      expect(
        'zh_Hant_TW'.toLocale(),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
      expect('en-US'.toLocale(separator: '-'), const Locale('en', 'US'));
    });
  });

  group('num extensions', () {
    test('roundToPrecision', () {
      expect(3.14159.roundToPrecision(), 3.14);
      expect(3.14159.roundToPrecision(numbersToRoundTo: 3), 3.142);
    });

    test('isZero', () {
      expect(0.000000001.isZero(), isTrue);
      expect(0.1.isZero(), isFalse);
      expect((-0.0000000001).isZero(), isTrue);
    });
  });

  group('Locale extensions', () {
    test('supports', () {
      expect(const Locale('en').supports(const Locale('en', 'US')), isTrue);
      expect(
        const Locale('en', 'US').supports(const Locale('en', 'GB')),
        isFalse,
      );
      expect(const Locale('en').supports(const Locale('ar')), isFalse);
      expect(
        const Locale('en', 'US').supports(const Locale('en', 'US')),
        isTrue,
      );
    });

    test('supports respects scriptCode', () {
      const hant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      const hans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
      expect(hant.supports(hans), isFalse);
      expect(hant.supports(hant), isTrue);
      expect(const Locale('zh').supports(hant), isTrue);
    });

    test('toStringWithSeparator', () {
      expect(const Locale('en').toStringWithSeparator(), 'en');
      expect(const Locale('en', 'US').toStringWithSeparator(), 'en-US');
      expect(
        const Locale('en', 'US').toStringWithSeparator(separator: '_'),
        'en_US',
      );
    });

    test('XLocale.locale builds locale with scriptCode', () {
      const x = XLocale(
        id: 'zh',
        name: 'Chinese',
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      );
      expect(
        x.locale,
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      );
      const plain = XLocale(id: 'en', name: 'English', languageCode: 'en');
      expect(plain.locale, const Locale('en'));
    });

    test('XLocale equality', () {
      const a = XLocale(id: 'en', name: 'English', languageCode: 'en');
      const b = XLocale(id: 'en', name: 'English', languageCode: 'en');
      expect(a, b);
    });
  });
}
