import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/easy_localization/file_loaders/file_loader.dart';
import 'package:playx_localization/src/easy_localization/linked_file_resolver.dart';
import 'package:playx_localization/src/tools/translation_files.dart';

class MapFileLoader implements FileLoader {
  final Map<String, String> files;
  final List<String> requested = [];
  MapFileLoader(Map<String, Object> data)
    : files = data.map((k, v) => MapEntry(k, json.encode(v)));

  @override
  Future<String> loadString(String path) async {
    requested.add(path);
    final c = files[path];
    if (c == null) throw StateError('missing $path');
    return c;
  }
}

RootBundleAssetLoader loaderFor(MapFileLoader f) => RootBundleAssetLoader(
  fileLoader: f,
  linkedFileResolver: JsonLinkedFileResolver(fileLoader: f),
);

const hantTW = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
  countryCode: 'TW',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('locale string order', () {
    test('toStringWithSeparator is language-script-country', () {
      expect(hantTW.toStringWithSeparator(), 'zh-Hant-TW');
      expect(hantTW.toStringWithSeparator(separator: '_'), 'zh_Hant_TW');
      expect(hantTW.toStringWithSeparator(), hantTW.toLanguageTag());
    });

    test('legacy order is language-country-script', () {
      expect(hantTW.toLegacyStringWithSeparator(), 'zh-TW-Hant');
    });

    test('orders agree when there is no script or no country', () {
      for (final l in const [
        Locale('en'),
        Locale('en', 'US'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ]) {
        expect(l.toStringWithSeparator(), l.toLegacyStringWithSeparator());
      }
    });
  });

  group('RootBundleAssetLoader', () {
    test('loads the new BCP-47 file name', () async {
      final f = MapFileLoader({
        'a/zh-Hant-TW.json': {'k': 'new'},
        'a/zh-TW-Hant.json': {'k': 'old'},
      });
      expect((await loaderFor(f).load('a', hantTW))!['k'], 'new');
    });

    test('falls back to the legacy file name', () async {
      final f = MapFileLoader({
        'a/zh-TW-Hant.json': {'k': 'old'},
      });
      expect((await loaderFor(f).load('a', hantTW))!['k'], 'old');
      expect(f.requested, ['a/zh-Hant-TW.json', 'a/zh-TW-Hant.json']);
    });

    test('throws when neither exists', () async {
      expect(loaderFor(MapFileLoader({})).load('a', hantTW), throwsStateError);
    });

    test('plain locales are unaffected', () async {
      final f = MapFileLoader({
        'a/en-US.json': {'k': 'v'},
      });
      expect(
        (await loaderFor(f).load('a', const Locale('en', 'US')))!['k'],
        'v',
      );
      expect(f.requested, ['a/en-US.json']);
    });

    test(
      'linked files use the script folder, then the legacy folder',
      () async {
        final f = MapFileLoader({
          'a/zh-Hant-TW.json': {'auth': ':/auth.json', 'other': ':/other.json'},
          'a/zh-Hant-TW/auth.json': {'login': 'new'},
          // Only exists in the old folder layout (script ignored).
          'a/zh-TW/other.json': {'x': 'old'},
        });
        final result = (await loaderFor(f).load('a', hantTW))!;
        expect(result['auth'], {'login': 'new'});
        expect(result['other'], {'x': 'old'});
      },
    );
  });

  group('JsonLinkedFileResolver paths', () {
    final r = JsonLinkedFileResolver(fileLoader: MapFileLoader({}));

    test('getLinkedLocalePath', () {
      expect(
        r.getLinkedLocalePath(
          'a',
          'f.json',
          'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
        'a/zh-Hant-TW/f.json',
      );
      expect(
        r.getLinkedLocalePath('a', 'f.json', 'en', countryCode: 'US'),
        'a/en-US/f.json',
      );
      expect(r.getLinkedLocalePath('a', 'f.json', 'en'), 'a/en/f.json');
      expect(
        r.getLegacyLinkedLocalePath('a', 'f.json', 'zh', countryCode: 'TW'),
        'a/zh-TW/f.json',
      );
    });
  });

  group('tool file names', () {
    test('parses language, script and country', () {
      TranslationFile f(String n) => TranslationFile.fromPath('dir/$n.json');
      expect(f('en').languageCode, 'en');
      expect(f('en-US').countryCode, 'US');
      expect(f('zh-Hant').scriptCode, 'Hant');
      expect(f('zh-Hant').countryCode, isNull);
      expect(f('zh-Hant-TW').scriptCode, 'Hant');
      expect(f('zh-Hant-TW').countryCode, 'TW');
      expect(f('zh-TW-Hant').scriptCode, 'Hant');
      expect(f('zh-TW-Hant').countryCode, 'TW');
      expect(f('pt_BR').countryCode, 'BR');
    });
  });
}
