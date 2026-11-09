import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');

Future<void> boot(XLocale start) => PlayxLocalization.boot(
  config: PlayxLocaleConfig(
    supportedLocales: const [en, ar],
    startLocale: start,
    assetLoader: MemoryAssetLoader({
      'en': {'k': 'v'},
      'ar': {'k': 'v'},
    }),
    storage: PlayxMemoryLocaleStorage(),
    logLocaleChanges: false,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('explicit locale', () {
    test('toFormattedCurrencyNumber', () {
      expect(1234567.5.toFormattedCurrencyNumber(), '1,234,567.50');
      expect(
        1234.5.toFormattedCurrencyNumber(currencySymbol: r'$', locale: 'en'),
        r'$1,234.50',
      );
      expect(
        1234.5.toFormattedCurrencyNumber(format: '#,##0', locale: 'en'),
        '1,235',
      );
    });

    test('toFormattedNumber', () {
      expect(
        1234.56.toFormattedNumber(format: '#,##0.0', locale: 'en_US'),
        '1,234.6',
      );
    });

    test('Arabic and English numerals', () {
      expect(123.toLocalizedEnglishNumber(), '123');
      expect(
        123.toLocalizedArabicNumber(),
        NumberFormat('#.##', 'ar_EG').format(123),
      );
      expect(123.toLocalizedArabicNumber(), contains('١'));
      expect(1.5.toLocalizedEnglishNumber(format: '0.00'), '1.50');
      expect(
        1.5.toLocalizedArabicNumber(format: '0.00'),
        NumberFormat('0.00', 'ar_EG').format(1.5),
      );
    });
  });

  group('current locale', () {
    test('English', () async {
      await boot(en);
      expect(1234.5.toLocalizedCurrencyNumber(), '1,234.50');
      expect(
        1234.5.toLocalizedCurrencyNumber(currencySymbol: r'$'),
        r'$1,234.50',
      );
      expect(1234.5.toLocalizedCurrencyNumber(locale: 'en'), '1,234.50');
      expect(1234.5.toLocalizedNumber(), '1234.5');
      expect(1234.5.toLocalizedNumber(format: '0.0', locale: 'en'), '1234.5');
      expect(7.toLocalizedArabicOrEnglishNumber(), '7');
    });

    test('Arabic', () async {
      await boot(ar);
      expect(
        1234.5.toLocalizedCurrencyNumber(),
        NumberFormat('#,##0.00##', 'ar_EG').format(1234.5),
      );
      expect(
        7.toLocalizedArabicOrEnglishNumber(),
        NumberFormat('#.##', 'ar_EG').format(7),
      );
      expect(7.toLocalizedArabicOrEnglishNumber(), '٧');
    });
  });
}
