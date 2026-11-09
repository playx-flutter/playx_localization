import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/src/tools/translation_validator.dart';

List<String> messages(List<ValidationIssue> issues) =>
    issues.map((i) => i.toString()).toList();

void main() {
  group('placeholdersOf', () {
    test('counts positional and named placeholders', () {
      expect(placeholdersOf('Hi {name}, {} and {}'), {'name': 1, '': 2});
      expect(placeholdersOf('plain'), isEmpty);
    });
  });

  group('validateTranslations', () {
    test('reports missing and extra keys', () {
      final issues = validateTranslations(baseLocale: 'en', locales: {
        'en': {'a': 'A', 'b': 'B'},
        'ar': {'a': 'ا', 'c': 'ج'},
      });
      expect(
        messages(issues),
        containsAll([
          'error: [ar] b: missing (present in en)',
          'warning: [ar] c: not present in en',
        ]),
      );
    });

    test('reports placeholder mismatches, ignoring order', () {
      final issues = validateTranslations(baseLocale: 'en', locales: {
        'en': {'ok': '{a} then {b}', 'bad': 'Hi {name}', 'pos': '{} items'},
        'ar': {'ok': '{b} ثم {a}', 'bad': 'مرحبا', 'pos': '{} {} عناصر'},
      });
      final errors = issues.where((i) => i.severity == IssueSeverity.error);
      expect(errors.map((e) => e.key), unorderedEquals(['bad', 'pos']));
    });

    test('compares nested keys and plural groups', () {
      final issues = validateTranslations(baseLocale: 'en', locales: {
        'en': {
          'home': {'title': 'T'},
          'item': {'one': '{} item', 'other': '{} items'},
        },
        'ar': {
          'home': {'title': 'ع'},
          'item': {'zero': 'لا', 'other': '{} عناصر'},
        },
      });
      expect(issues, isEmpty);
    });

    test('flags plural groups without other, and empty values', () {
      final issues = validateTranslations(baseLocale: 'en', locales: {
        'en': {
          'item': {'one': 'item'},
          'blank': '  ',
        },
      });
      expect(
        messages(issues),
        containsAll([
          'error: [en] item: plural group is missing the required "other" form',
          'warning: [en] blank: value is empty',
        ]),
      );
    });

    test('identical locales produce no issues', () {
      expect(
        validateTranslations(baseLocale: 'en', locales: {
          'en': {'a': '{x}'},
          'fr': {'a': '{x}'},
        }),
        isEmpty,
      );
    });
  });

  group('runValidate', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('playx_val_'));
    tearDown(() => dir.deleteSync(recursive: true));

    String p(String name) => '${dir.path}${Platform.pathSeparator}$name';
    void write(String name, Object data) =>
        File(p(name)).writeAsStringSync(data is String ? data : json.encode(data));

    test('passes for consistent files', () async {
      write('en.json', {'a': 'A {n}'});
      write('ar.json', {'a': 'ا {n}'});
      final out = StringBuffer();
      expect(await runValidate(['--dir', dir.path], out: out), 0);
      expect(out.toString(), contains('0 errors'));
    });

    test('fails on missing keys, warnings only with --strict', () async {
      write('en.json', {'a': 'A', 'b': 'B'});
      write('ar.json', {'a': 'ا'});
      expect(await runValidate(['--dir', dir.path], out: StringBuffer()), 1);

      write('ar.json', {'a': 'ا', 'b': 'ب', 'extra': 'x'});
      expect(await runValidate(['--dir', dir.path], out: StringBuffer()), 0);
      expect(
          await runValidate(['--dir', dir.path, '--strict'],
              out: StringBuffer()),
          1);
    });

    test('reports invalid JSON and broken links', () async {
      write('en.json', {'a': 'A', 'l': ':/missing.json'});
      write('ar.json', '{ not json');
      final out = StringBuffer();
      expect(await runValidate(['--dir', dir.path], out: out), 1);
      expect(out.toString(), contains('[ar]'));
      expect(out.toString(), contains('[en]'));
    });

    test('--src reports unused keys', () async {
      write('en.json', {'used_literal': 'A', 'used_const': 'B', 'unused': 'C'});
      Directory(p('src')).createSync();
      File(p('src/a.dart')).writeAsStringSync(
          "final a = 'used_literal'.tr(); final b = AppTrans.usedConst;");
      final out = StringBuffer();
      await runValidate(['--dir', dir.path, '--src', p('src')], out: out);
      expect(out.toString(), contains('unused: unused in'));
      expect(out.toString(), isNot(contains('used_literal: unused')));
      expect(out.toString(), isNot(contains('used_const: unused')));
    });

    test('errors for missing directory or base locale', () async {
      final err = StringBuffer();
      expect(
          await runValidate(['--dir', p('nope')], out: StringBuffer(), err: err),
          66);
      write('fr.json', {'a': 'A'});
      expect(
          await runValidate(['--dir', dir.path],
              out: StringBuffer(), err: err),
          66);
      expect(
          await runValidate(['--dir', dir.path, '--base', 'fr'],
              out: StringBuffer(), err: err),
          0);
    });
  });
}
