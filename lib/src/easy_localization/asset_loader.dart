import 'dart:convert';
import 'dart:ui';

import '../../playx_localization.dart';
import '../controller/controller.dart';
import 'file_loaders/io_file_loader.dart';

/// Base class for building your own asset loader, for example to read other
/// file formats or to fetch translations from the network.
///
/// [fileLoader] and [linkedFileResolver] are only used by loaders that read
/// files and resolve `":/linked.json"` references (like [RootBundleAssetLoader]).
/// A custom loader does not need them.
///
/// Example:
/// ```dart
/// class HttpAssetLoader extends AssetLoader {
///   const HttpAssetLoader();
///
///   @override
///   Future<Map<String, dynamic>?> load(String path, Locale locale) async {
///     final response = await http.get(Uri.parse('$path/${locale.languageCode}.json'));
///     return json.decode(response.body) as Map<String, dynamic>;
///   }
/// }
/// ```
abstract class AssetLoader {
  final FileLoader fileLoader;
  final LinkedFileResolver linkedFileResolver;

  const AssetLoader({
    this.linkedFileResolver = const JsonLinkedFileResolver(
      fileLoader: RootBundleFileLoader(),
    ),
    this.fileLoader = const RootBundleFileLoader(),
  });

  /// Loads the translations of [locale] from [path].
  /// Throwing means the locale could not be loaded.
  Future<Map<String, dynamic>?> load(String path, Locale locale);
}

///
/// default used is RootBundleAssetLoader which uses flutter's assetloader
///
class RootBundleAssetLoader extends AssetLoader {
  const RootBundleAssetLoader({
    required super.linkedFileResolver,
    required super.fileLoader,
  });

  factory RootBundleAssetLoader.fromRootBundle() {
    return const RootBundleAssetLoader(
      linkedFileResolver: JsonLinkedFileResolver(
        fileLoader: RootBundleFileLoader(),
      ),
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
        'Loaded $legacyPath. Rename it to $localePath, the old name order will be removed in a future version.',
      );
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
