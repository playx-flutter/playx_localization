import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/easy_localization/file_loaders/io_file_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IOFileLoader', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('playx_io_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('reads an existing file', () async {
      final file = File('${dir.path}/en.json')..writeAsStringSync('{"a":"b"}');
      expect(await const IOFileLoader().loadString(file.path), '{"a":"b"}');
    });

    test('throws for a missing file', () async {
      expect(
        const IOFileLoader().loadString('${dir.path}/nope.json'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test(
      'RootBundleAssetLoader.fromIOFile loads translations from disk',
      () async {
        File(
          '${dir.path}/en.json',
        ).writeAsStringSync(json.encode({'a': 'b', 'l': ':/x.json'}));
        Directory('${dir.path}/en').createSync();
        File('${dir.path}/en/x.json').writeAsStringSync('{"k":"v"}');

        final result = await RootBundleAssetLoader.fromIOFile().load(
          dir.path,
          const Locale('en'),
        );
        expect(result, {
          'a': 'b',
          'l': {'k': 'v'},
        });
      },
    );
  });

  group('RootBundleFileLoader', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final key = utf8.decode(message!.buffer.asUint8List());
            if (key == 'assets/translations/en.json') {
              return ByteData.sublistView(
                Uint8List.fromList(utf8.encode('{"hello":"Hello"}')),
              );
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('loads a string from the asset bundle', () async {
      expect(
        await const RootBundleFileLoader().loadString(
          'assets/translations/en.json',
        ),
        '{"hello":"Hello"}',
      );
    });

    test('RootBundleAssetLoader.fromRootBundle loads translations', () async {
      expect(
        await RootBundleAssetLoader.fromRootBundle().load(
          'assets/translations',
          const Locale('en'),
        ),
        {'hello': 'Hello'},
      );
    });

    test('a missing asset throws', () async {
      expect(
        const RootBundleFileLoader().loadString('assets/missing.json'),
        throwsFlutterError,
      );
    });
  });
}
