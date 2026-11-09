import 'dart:convert';
import 'dart:ui';

import '../../playx_localization.dart';
import '../controller/controller.dart';
import 'file_loaders/file_loader.dart';
import 'file_loaders/io_file_loader.dart';
import 'file_loaders/root_bundle_file_loader.dart';
import 'linked_file_resolver.dart';

/// abstract class used to building your Custom AssetLoader
/// Example:
/// ```
///class FileAssetLoader extends AssetLoader {
///  @override
///  Future<Map<String, dynamic>> load(String path, Locale locale) async {
///    final file = File(path);
///    return json.decode(await file.readAsString());
///  }
///}
/// ```
abstract class AssetLoader {
  // Place inside class RootBundleAssetLoader
  final FileLoader fileLoader;
  final LinkedFileResolver linkedFileResolver;

  const AssetLoader(
      {required this.linkedFileResolver, required this.fileLoader});

  Future<Map<String, dynamic>?> load(String path, Locale locale);
}

///
/// default used is RootBundleAssetLoader which uses flutter's assetloader
///
class RootBundleAssetLoader extends AssetLoader {
  const RootBundleAssetLoader(
      {required super.linkedFileResolver, required super.fileLoader});

  factory RootBundleAssetLoader.fromRootBundle() {
    return const RootBundleAssetLoader(
      linkedFileResolver:
          JsonLinkedFileResolver(fileLoader: RootBundleFileLoader()),
      fileLoader: RootBundleFileLoader(),
    );
  }

  factory RootBundleAssetLoader.fromIOFile() {
    return const RootBundleAssetLoader(
      linkedFileResolver: JsonLinkedFileResolver(fileLoader: IOFileLoader()),
      fileLoader: IOFileLoader(),
    );
  }

  /// `base/language[-script][-country].json`, e.g. `assets/zh-Hant-TW.json`.
  String getLocalePath(String basePath, Locale locale) {
    return '$basePath/${locale.toStringWithSeparator(separator: "-")}.json';
  }

  /// File name used before 0.5.0, `base/language[-country][-script].json`
  /// (e.g. `assets/zh-TW-Hant.json`).
  String getLegacyLocalePath(String basePath, Locale locale) {
    return '$basePath/${locale.toLegacyStringWithSeparator(separator: "-")}.json';
  }

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final localePath = getLocalePath(path, locale);
    final legacyPath = getLegacyLocalePath(path, locale);
    PlayxLocaleController.logger?.debug('Load asset from $path');

    String content;
    try {
      content = await fileLoader.loadString(localePath);
    } catch (_) {
      // Keep assets named in the old `zh-TW-Hant` order working.
      if (legacyPath == localePath) rethrow;
      content = await fileLoader.loadString(legacyPath);
      PlayxLocaleController.logger?.warning(
          'Loaded $legacyPath. Rename it to $localePath, the old name order will be removed in a future version.');
    }

    Map<String, dynamic> baseJson = json.decode(content);
    return await linkedFileResolver.resolveLinkedFiles(
      basePath: path,
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      scriptCode: locale.scriptCode,
      baseJson: baseJson,
    );
  }
}
