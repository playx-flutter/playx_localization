import 'dart:convert';

import 'file_loaders/file_loader.dart';

/// Resolves linked translation files by loading referenced files and merging them
/// into the base JSON structure. Handles the ':/filename.json' syntax used in linked files.

abstract class LinkedFileResolver {
  final int maxLinkedDepth = 32;
  final FileLoader fileLoader;

  const LinkedFileResolver({required this.fileLoader});

  Future<Map<String, dynamic>> resolveLinkedFiles({
    required String basePath,
    required String languageCode,
    required Map<String, dynamic> baseJson,
    Set<String>? visited,
    int depth = 0,
    String? countryCode,
    String? scriptCode,
  });

  /// Path of a linked file inside the folder of the locale:
  /// `base/language[-script][-country]/file`.
  String getLinkedLocalePath(
      String basePath, String filePath, String languageCode,
      {String? countryCode, String? scriptCode}) {
    final folder = [
      languageCode,
      if (scriptCode != null && scriptCode.isNotEmpty) scriptCode,
      if (countryCode != null && countryCode.isNotEmpty) countryCode,
    ].join('-');
    return '$basePath/$folder/$filePath';
  }

  /// Path used before 0.5.0, which ignored the script code
  /// (`base/language[-country]/file`). Only differs when [scriptCode] is set.
  String getLegacyLinkedLocalePath(
          String basePath, String filePath, String languageCode,
          {String? countryCode}) =>
      getLinkedLocalePath(basePath, filePath, languageCode,
          countryCode: countryCode);
}

class JsonLinkedFileResolver extends LinkedFileResolver {
  const JsonLinkedFileResolver({required super.fileLoader});

  @override
  Future<Map<String, dynamic>> resolveLinkedFiles({
    required String basePath,
    required String languageCode,
    required Map<String, dynamic> baseJson,
    Set<String>? visited,
    int depth = 0,
    String? countryCode,
    String? scriptCode,
  }) async {
    visited ??= <String>{};

    if (depth > maxLinkedDepth) {
      throw StateError(
          'Maximum linked files depth ($maxLinkedDepth) exceeded for $languageCode at $basePath.');
    }

    final Map<String, dynamic> fullJson = Map<String, dynamic>.from(baseJson);

    for (final entry in baseJson.entries) {
      final key = entry.key;
      var value = entry.value;

      if (value is String && value.startsWith(':/')) {
        final rawPath = value.substring(2).trim();
        final linkedAssetPath = getLinkedLocalePath(
            basePath, rawPath, languageCode,
            countryCode: countryCode, scriptCode: scriptCode);
        // Folders of locales with a script code used to ignore the script.
        final legacyAssetPath = getLegacyLinkedLocalePath(
            basePath, rawPath, languageCode,
            countryCode: countryCode);

        if (visited.contains(linkedAssetPath)) {
          throw StateError(
              'Cyclic linked files detected at "$linkedAssetPath" (key: "$key").');
        }

        try {
          String linkedContent;
          try {
            linkedContent = await fileLoader.loadString(linkedAssetPath);
          } catch (_) {
            if (legacyAssetPath == linkedAssetPath) rethrow;
            linkedContent = await fileLoader.loadString(legacyAssetPath);
          }
          final Map<String, dynamic> linkedJson =
              json.decode(linkedContent) as Map<String, dynamic>;

          // Track only the ancestor chain so the same file can be linked
          // from several keys without being reported as a cycle.
          final resolved = await resolveLinkedFiles(
            basePath: basePath,
            languageCode: languageCode,
            baseJson: linkedJson,
            visited: {...visited, linkedAssetPath},
            depth: depth + 1,
            countryCode: countryCode,
            scriptCode: scriptCode,
          );
          fullJson[key] = resolved;
        } catch (e) {
          throw StateError(
            'Error resolving linked file "$linkedAssetPath" for key "$key": $e',
          );
        }
      } else if (value is Map<String, dynamic>) {
        fullJson[key] = await resolveLinkedFiles(
          basePath: basePath,
          languageCode: languageCode,
          baseJson: value,
          visited: visited,
          depth: depth,
          countryCode: countryCode,
          scriptCode: scriptCode,
        );
      }
    }

    return fullJson;
  }
}
