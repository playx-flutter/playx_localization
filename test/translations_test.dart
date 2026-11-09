import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/src/controller/translation_manager.dart';
import 'package:playx_localization/src/easy_localization/translations.dart';

void main() {
  group('Translations', () {
    final t = Translations({
      'title': 'Title',
      'a.b': 'flat dotted',
      'home': {
        'title': 'Home',
        'nested': {'deep': 'Deep'},
      },
    });

    test('gets flat keys', () {
      expect(t.get('title'), 'Title');
    });

    test('gets nested keys', () {
      expect(t.get('home.title'), 'Home');
      expect(t.get('home.nested.deep'), 'Deep');
    });

    test('prefers literal dotted key', () {
      expect(t.get('a.b'), 'flat dotted');
    });

    test('returns null for missing keys', () {
      expect(t.get('missing'), isNull);
      expect(t.get('home.missing'), isNull);
    });

    test('caches nested lookups', () {
      t.get('home.title');
      expect(t.isNestedCached('home.title'), isTrue);
    });
  });

  group('MapExtension.addAllRecursive', () {
    test('merges nested maps and overrides leaves', () {
      final base = <String, dynamic>{
        'a': '1',
        'n': {'x': '1', 'y': '1'},
      };
      base.addAllRecursive({
        'a': '2',
        'b': '3',
        'n': {'y': '2', 'z': '2'},
      });
      expect(base, {
        'a': '2',
        'b': '3',
        'n': {'x': '1', 'y': '2', 'z': '2'},
      });
    });

    test('replaces map with non-map value', () {
      final base = <String, dynamic>{
        'n': {'x': '1'},
      };
      base.addAllRecursive({'n': 'flat'});
      expect(base['n'], 'flat');
    });
  });
}
