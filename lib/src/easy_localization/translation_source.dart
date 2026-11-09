import 'dart:ui';

import '../controller/controller.dart';
import 'asset_loader.dart';

/// A set of translations contributed by something other than the app itself,
/// typically another package that ships its own translation files.
///
/// Register it with `PlayxLocalization.registerTranslations`.
///
/// Translations from sources have the **lowest priority**: keys defined by the
/// app (`PlayxLocaleConfig.assetLoader` / `extraAssetLoaders`) always override
/// keys with the same name from a source. Between sources, the one registered
/// later wins.
///
/// A source does not have to provide every locale the app supports. Missing
/// locales are skipped, and a regional locale like `en-US` falls back to
/// `en` when the exact file is not found.
class PlayxTranslationSource {
  /// Unique id of the source, usually the package name.
  /// Registering a source with an existing id replaces the previous one.
  final String id;

  /// Base path of the translation files, passed to [loader].
  final String path;

  /// Loader used to read the translation files.
  final AssetLoader loader;

  /// Optional key prefix. With `namespace: 'my_pkg'` a file containing
  /// `{"title": "Hi"}` is read as `my_pkg.title`. Dots create nested levels.
  /// Use it to avoid key collisions with the app or other packages.
  final String? namespace;

  PlayxTranslationSource({
    required this.id,
    required this.path,
    AssetLoader? loader,
    this.namespace,
  }) : assert(id.isNotEmpty, 'id can not be empty'),
       assert(path.isNotEmpty, 'path can not be empty'),
       loader = loader ?? RootBundleAssetLoader.fromRootBundle();

  /// Translations bundled as assets of another package.
  ///
  /// The package must declare the folder in its pubspec `assets:`; this resolves
  /// to `packages/<package>/<path>`.
  ///
  /// ```dart
  /// await PlayxLocalization.registerTranslations(
  ///   PlayxTranslationSource.package(package: 'my_pkg', namespace: 'my_pkg'),
  /// );
  /// ```
  factory PlayxTranslationSource.package({
    required String package,
    String path = 'assets/translations',
    String? namespace,
    AssetLoader? loader,
  }) {
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return PlayxTranslationSource(
      id: package,
      path: 'packages/$package/$relative',
      namespace: namespace,
      loader: loader,
    );
  }

  /// Loads the translations for [locale], or `null` if the source has none for
  /// that locale (or its language).
  Future<Map<String, dynamic>?> load(Locale locale) async {
    final candidates = <Locale>{
      locale,
      if (locale.scriptCode != null)
        Locale.fromSubtags(
          languageCode: locale.languageCode,
          scriptCode: locale.scriptCode,
        ),
      Locale(locale.languageCode),
    };

    for (final candidate in candidates) {
      try {
        final data = await loader.load(path, candidate);
        if (data != null) return _applyNamespace(data);
      } catch (_) {
        // Not available for this candidate, try the next one.
      }
    }
    PlayxLocaleController.logger?.debug(
      'Translation source "$id" has no translations for $locale',
    );
    return null;
  }

  Map<String, dynamic> _applyNamespace(Map<String, dynamic> data) {
    final ns = namespace;
    if (ns == null || ns.isEmpty) return data;
    Map<String, dynamic> result = data;
    for (final part in ns.split('.').reversed) {
      result = {part: result};
    }
    return result;
  }
}

/// Holds the translation sources registered by packages.
class TranslationSourceRegistry {
  TranslationSourceRegistry._();

  static final Map<String, PlayxTranslationSource> _sources = {};

  /// Registered sources, in registration order.
  static List<PlayxTranslationSource> get sources =>
      List.unmodifiable(_sources.values);

  static void register(PlayxTranslationSource source) {
    // Re-registering moves the source to the end, so it takes priority again.
    _sources.remove(source.id);
    _sources[source.id] = source;
  }

  static bool unregister(String id) => _sources.remove(id) != null;

  static void clear() => _sources.clear();
}
