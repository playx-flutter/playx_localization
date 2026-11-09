import 'package:flutter/widgets.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/easy_localization/file_loaders/file_loader.dart';
import 'package:playx_localization/src/easy_localization/linked_file_resolver.dart';

class _NoFiles extends FileLoader {
  @override
  Future<String> loadString(String path) async => throw StateError(path);
}

/// Serves translations from memory, keyed by `Locale.toLanguageTag()`.
class MemoryAssetLoader extends AssetLoader {
  final Map<String, Map<String, dynamic>> data;

  MemoryAssetLoader(this.data)
      : super(
          fileLoader: _NoFiles(),
          linkedFileResolver: JsonLinkedFileResolver(fileLoader: _NoFiles()),
        );

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final d = data[locale.toLanguageTag()];
    if (d == null) throw FlutterError('No translations for $locale');
    return Map<String, dynamic>.from(d);
  }
}
