import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';

import 'helpers.dart';

/// A loader written the way a user would: no file loader or resolver needed.
class InMemoryLoader extends AssetLoader {
  const InMemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    return {'title': '$path/${locale.languageCode}'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a custom AssetLoader works without file loader arguments', () async {
    const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
    await PlayxLocalization.boot(
      config: PlayxLocaleConfig(
        supportedLocales: const [en],
        path: 'remote',
        assetLoader: const InMemoryLoader(),
        storage: PlayxMemoryLocaleStorage(),
        logLocaleChanges: false,
      ),
    );
    expect('title'.tr(), 'remote/en');
  });

  test('default file loader and resolver are the asset bundle ones', () {
    const loader = InMemoryLoader();
    expect(loader.fileLoader, isA<RootBundleFileLoader>());
    expect(loader.linkedFileResolver, isA<JsonLinkedFileResolver>());
  });

  test('MemoryAssetLoader helper still compiles with the exports', () {
    expect(MemoryAssetLoader({}).fileLoader, isA<FileLoader>());
  });
}
