import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/src/easy_localization/file_loaders/file_loader.dart';
import 'package:playx_localization/src/easy_localization/linked_file_resolver.dart';

class FakeFileLoader extends FileLoader {
  final Map<String, String> files;
  FakeFileLoader(this.files);

  @override
  Future<String> loadString(String path) async {
    final content = files[path];
    if (content == null) throw StateError('missing $path');
    return content;
  }
}

void main() {
  JsonLinkedFileResolver resolverFor(Map<String, Object> files) =>
      JsonLinkedFileResolver(
        fileLoader: FakeFileLoader(
            files.map((k, v) => MapEntry(k, json.encode(v)))),
      );

  test('getLinkedLocalePath with and without country', () {
    final r = resolverFor({});
    expect(r.getLinkedLocalePath('assets', 'a.json', 'en'), 'assets/en/a.json');
    expect(r.getLinkedLocalePath('assets', 'a.json', 'en', countryCode: 'US'),
        'assets/en-US/a.json');
  });

  test('returns plain json unchanged', () async {
    final result = await resolverFor({}).resolveLinkedFiles(
      basePath: 'assets',
      languageCode: 'en',
      baseJson: {
        'a': 'b',
        'n': {'c': 'd'}
      },
    );
    expect(result, {
      'a': 'b',
      'n': {'c': 'd'}
    });
  });

  test('resolves linked files, including nested maps', () async {
    final r = resolverFor({
      'assets/en/auth.json': {'login': 'Login'},
      'assets/en-US/auth.json': {'login': 'Sign in'},
    });
    final base = {
      'auth': ':/auth.json',
      'group': {'inner': ':/auth.json'},
    };
    expect(
      await r.resolveLinkedFiles(
          basePath: 'assets', languageCode: 'en', baseJson: base),
      {
        'auth': {'login': 'Login'},
        'group': {
          'inner': {'login': 'Login'}
        },
      },
    );
    expect(
      (await r.resolveLinkedFiles(
          basePath: 'assets',
          languageCode: 'en',
          countryCode: 'US',
          baseJson: base))['auth'],
      {'login': 'Sign in'},
    );
  });

  test('resolves chained links', () async {
    final r = resolverFor({
      'assets/en/a.json': {'b': ':/b.json'},
      'assets/en/b.json': {'k': 'v'},
    });
    final result = await r.resolveLinkedFiles(
        basePath: 'assets', languageCode: 'en', baseJson: {'a': ':/a.json'});
    expect(result, {
      'a': {
        'b': {'k': 'v'}
      }
    });
  });

  test('throws on missing linked file', () async {
    expect(
      resolverFor({}).resolveLinkedFiles(
          basePath: 'assets', languageCode: 'en', baseJson: {'a': ':/x.json'}),
      throwsStateError,
    );
  });

  test('throws on cyclic links', () async {
    final r = resolverFor({
      'assets/en/a.json': {'b': ':/b.json'},
      'assets/en/b.json': {'a': ':/a.json'},
    });
    expect(
      r.resolveLinkedFiles(
          basePath: 'assets', languageCode: 'en', baseJson: {'a': ':/a.json'}),
      throwsStateError,
    );
  });
}
