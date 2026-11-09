import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/src/tools/key_generator.dart';
import 'package:playx_localization/src/tools/translation_files.dart';

void main() {
  group('keyToIdentifier', () {
    test('converts separators to lowerCamelCase', () {
      expect(keyToIdentifier('app_name'), 'appName');
      expect(keyToIdentifier('home.sign-in title'), 'homeSignInTitle');
      expect(keyToIdentifier('alreadyCamel'), 'alreadyCamel');
      expect(keyToIdentifier('HTTP_error'), 'httpError');
    });

    test('handles digits and reserved words', () {
      expect(keyToIdentifier('404_error'), 'k404Error');
      expect(keyToIdentifier('default'), 'defaultKey');
      expect(keyToIdentifier('class'), 'classKey');
      expect(keyToIdentifier('___'), 'key');
    });
  });

  group('flattenTranslations', () {
    test('flattens nested groups and treats plural groups as one key', () {
      final flat = flattenTranslations({
        'title': 'T',
        'home': {
          'welcome': 'Hi',
          'deep': {'x': 'X'},
        },
        'item': {'one': '{} item', 'other': '{} items'},
      });
      expect(flat, {
        'title': 'T',
        'home.welcome': 'Hi',
        'home.deep.x': 'X',
        'item': '{} items',
      });
    });

    test('a group with other keys next to plural forms is not a plural group',
        () {
      expect(isPluralGroup({'one': 'a', 'other': 'b', 'title': 'c'}), isFalse);
      expect(isPluralGroup({'one': 'a'}), isFalse);
    });
  });

  group('generateKeysSource', () {
    test('generates constants with doc comments', () {
      final src = generateKeysSource({
        'app_name': 'My App',
        'home': {'title': "It's \$5"},
      }, className: 'Keys');
      expect(src, contains('abstract class Keys {'));
      expect(src, contains("static const appName = 'app_name';"));
      expect(src, contains("static const homeTitle = 'home.title';"));
      expect(src, contains('/// My App'));
    });

    test('suffixes colliding names and warns', () {
      final warnings = <String>[];
      final src = generateKeysSource(
          {'a_b': '1', 'a.b': '2', 'aB': '3'},
          warnings: warnings);
      expect(src, contains("static const aB = 'a_b';"));
      expect(src, contains("static const aB2 = 'a.b';"));
      expect(src, contains("static const aB3 = 'aB';"));
      expect(warnings.length, 2);
    });

    test('is deterministic', () {
      final data = {'a': '1', 'b': '2'};
      expect(generateKeysSource(data), generateKeysSource(data));
    });
  });

  group('runGenerate', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('playx_gen_'));
    tearDown(() => dir.deleteSync(recursive: true));

    String p(String name) => '${dir.path}${Platform.pathSeparator}$name';

    test('writes the file, resolving linked files, and --check passes',
        () async {
      Directory(p('en')).createSync();
      File(p('en/auth.json')).writeAsStringSync(json.encode({'login': 'Login'}));
      File(p('en.json')).writeAsStringSync(
          json.encode({'title': 'T', 'auth': ':/auth.json'}));
      final out = StringBuffer();

      final code = await runGenerate([
        '--source', p('en.json'),
        '--output', p('gen/app_trans.dart'),
        '--class', 'AppTrans',
      ], out: out);
      expect(code, 0);

      final generated = File(p('gen/app_trans.dart')).readAsStringSync();
      expect(generated, contains("static const title = 'title';"));
      expect(generated, contains("static const authLogin = 'auth.login';"));

      final check = await runGenerate([
        '--source', p('en.json'),
        '--output', p('gen/app_trans.dart'),
        '--check',
      ], out: out);
      expect(check, 0);
    });

    test('--check fails when stale or missing', () async {
      File(p('en.json')).writeAsStringSync(json.encode({'a': '1'}));
      final err = StringBuffer();
      expect(
        await runGenerate(
            ['--source', p('en.json'), '--output', p('o.dart'), '--check'],
            out: StringBuffer(), err: err),
        1,
      );
      await runGenerate(['--source', p('en.json'), '--output', p('o.dart')],
          out: StringBuffer());
      File(p('en.json')).writeAsStringSync(json.encode({'a': '1', 'b': '2'}));
      expect(
        await runGenerate(
            ['--source', p('en.json'), '--output', p('o.dart'), '--check'],
            out: StringBuffer(), err: err),
        1,
      );
    });

    test('reports errors for missing source and bad class name', () async {
      final err = StringBuffer();
      expect(
          await runGenerate(['--source', p('nope.json')],
              out: StringBuffer(), err: err),
          66);
      expect(
          await runGenerate(['--source', p('nope.json'), '--class', '1bad'],
              out: StringBuffer(), err: err),
          64);
    });

    test('--help prints usage', () async {
      final out = StringBuffer();
      expect(await runGenerate(['--help'], out: out), 0);
      expect(out.toString(), contains('Usage:'));
    });
  });
}
