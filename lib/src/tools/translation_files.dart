import 'dart:convert';
import 'dart:io';

import '../easy_localization/file_loaders/file_loader.dart';
import '../easy_localization/linked_file_resolver.dart';

/// Reads files from disk. Pure Dart, so the tools run without Flutter.
class DiskFileLoader implements FileLoader {
  const DiskFileLoader();

  @override
  Future<String> loadString(String path) => File(path).readAsString();
}

/// A translation file on disk, e.g. `assets/translations/en-US.json`.
class TranslationFile {
  /// File name without extension, e.g. `en-US`.
  final String locale;
  final String path;
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  TranslationFile._(
    this.locale,
    this.path,
    this.languageCode,
    this.scriptCode,
    this.countryCode,
  );

  factory TranslationFile.fromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final locale = name.endsWith('.json')
        ? name.substring(0, name.length - '.json'.length)
        : name;
    final parts = locale.split(RegExp('[-_]'));
    String? script;
    String? country;
    if (parts.length == 2) {
      // `zh-Hant` (script) or `en-US` (country).
      if (parts[1].length == 4) {
        script = parts[1];
      } else {
        country = parts[1];
      }
    } else if (parts.length > 2) {
      // `zh-Hant-TW`, or the legacy order `zh-TW-Hant`.
      if (parts[1].length == 4) {
        script = parts[1];
        country = parts[2];
      } else {
        country = parts[1];
        script = parts[2];
      }
    }
    return TranslationFile._(locale, path, parts.first, script, country);
  }

  String get directory {
    final i = path.lastIndexOf(Platform.pathSeparator);
    return i == -1 ? '.' : path.substring(0, i);
  }

  /// Loads the file, resolving `:/linked.json` references like the runtime does.
  Future<Map<String, dynamic>> load() async {
    final decoded = json.decode(await File(path).readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$path must contain a JSON object.');
    }
    return const JsonLinkedFileResolver(
      fileLoader: DiskFileLoader(),
    ).resolveLinkedFiles(
      basePath: directory,
      languageCode: languageCode,
      countryCode: countryCode,
      scriptCode: scriptCode,
      baseJson: decoded,
    );
  }
}

/// Lists the `*.json` translation files directly inside [dir], sorted by name.
List<TranslationFile> findTranslationFiles(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return [];
  final files =
      d
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .map((f) => TranslationFile.fromPath(f.path))
          .toList()
        ..sort((a, b) => a.locale.compareTo(b.locale));
  return files;
}

const pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

/// Whether [map] is a plural group (`{"one": ..., "other": ...}`) which counts
/// as one key rather than a nested group.
bool isPluralGroup(Map<String, dynamic> map) =>
    map.containsKey('other') &&
    map.keys.every(pluralForms.contains) &&
    map.values.every((v) => v is String);

/// Flattens nested translations into `dotted.key -> value`.
/// Plural groups are kept as a single entry whose value is the `other` form.
Map<String, String> flattenTranslations(
  Map<String, dynamic> data, {
  String prefix = '',
}) {
  final out = <String, String>{};
  data.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      if (isPluralGroup(value)) {
        out[path] = value['other'] as String;
      } else {
        out.addAll(flattenTranslations(value, prefix: path));
      }
    } else if (value is String) {
      out[path] = value;
    }
  });
  return out;
}
