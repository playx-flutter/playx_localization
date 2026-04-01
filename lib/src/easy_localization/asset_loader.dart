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

  String getLocalePath(String basePath, Locale locale) {
    return '$basePath/${locale.toStringWithSeparator(separator: "-")}.json';
  }

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    var localePath = getLocalePath(path, locale);
    PlayxLocaleController.logger?.debug('Load asset from $path');

    Map<String, dynamic> baseJson =
        json.decode(await fileLoader.loadString(localePath));
    return await linkedFileResolver.resolveLinkedFiles(
      basePath: path,
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      baseJson: baseJson,
    );
  }
}
