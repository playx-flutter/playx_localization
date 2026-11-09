import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/src/easy_localization/plural_rules.dart';

PluralCase caseFor(String lang, num n, {int? precision = 0}) {
  startRuleEvaluation(n, precision);
  return pluralRules[lang]!();
}

void main() {
  group('plural rules', () {
    test('localeHasPluralRules', () {
      expect(localeHasPluralRules('en'), isTrue);
      expect(localeHasPluralRules('ar'), isTrue);
      expect(localeHasPluralRules('xx'), isFalse);
    });

    test('english: one / other', () {
      expect(caseFor('en', 1), PluralCase.ONE);
      expect(caseFor('en', 0), PluralCase.OTHER);
      expect(caseFor('en', 2), PluralCase.OTHER);
      expect(caseFor('en', 11), PluralCase.OTHER);
    });

    test('arabic: zero / one / two / few / many / other', () {
      expect(caseFor('ar', 0), PluralCase.ZERO);
      expect(caseFor('ar', 1), PluralCase.ONE);
      expect(caseFor('ar', 2), PluralCase.TWO);
      expect(caseFor('ar', 3), PluralCase.FEW);
      expect(caseFor('ar', 10), PluralCase.FEW);
      expect(caseFor('ar', 11), PluralCase.MANY);
      expect(caseFor('ar', 99), PluralCase.MANY);
      expect(caseFor('ar', 100), PluralCase.OTHER);
      expect(caseFor('ar', 103), PluralCase.FEW);
      expect(caseFor('ar', 111), PluralCase.MANY);
    });

    test('russian: one / few / many / other', () {
      expect(caseFor('ru', 1), PluralCase.ONE);
      expect(caseFor('ru', 21), PluralCase.ONE);
      expect(caseFor('ru', 11), PluralCase.MANY);
      expect(caseFor('ru', 2), PluralCase.FEW);
      expect(caseFor('ru', 24), PluralCase.FEW);
      expect(caseFor('ru', 12), PluralCase.MANY);
      expect(caseFor('ru', 5), PluralCase.MANY);
      expect(caseFor('ru', 0), PluralCase.MANY);
    });

    test('polish: one / few / many', () {
      expect(caseFor('pl', 1), PluralCase.ONE);
      expect(caseFor('pl', 2), PluralCase.FEW);
      expect(caseFor('pl', 22), PluralCase.FEW);
      expect(caseFor('pl', 12), PluralCase.MANY);
      expect(caseFor('pl', 5), PluralCase.MANY);
    });

    test('french: 0 and 1 are one', () {
      expect(caseFor('fr', 0), PluralCase.ONE);
      expect(caseFor('fr', 1), PluralCase.ONE);
      expect(caseFor('fr', 2), PluralCase.OTHER);
    });

    test('languages without plural distinction use other', () {
      for (final lang in ['ja', 'zh', 'ko', 'vi', 'th']) {
        if (!localeHasPluralRules(lang)) continue;
        expect(caseFor(lang, 1), PluralCase.OTHER, reason: lang);
        expect(caseFor(lang, 5), PluralCase.OTHER, reason: lang);
      }
    });

    test('hebrew: one / two / other', () {
      expect(caseFor('he', 1), PluralCase.ONE);
      expect(caseFor('he', 2), PluralCase.TWO);
      expect(caseFor('he', 5), PluralCase.OTHER);
    });

    test('every registered rule returns a case for typical numbers', () {
      for (final entry in pluralRules.entries) {
        for (final n in [0, 1, 2, 3, 5, 11, 21, 100, 1.5]) {
          startRuleEvaluation(n, null);
          expect(
            entry.value(),
            isA<PluralCase>(),
            reason: '${entry.key} with $n',
          );
        }
      }
    });
  });
}
