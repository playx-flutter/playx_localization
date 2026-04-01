import 'dart:io';

import 'file_loader.dart';

/// File loader implementation for Dart CLI applications using dart:io
class IOFileLoader implements FileLoader {
  const IOFileLoader();

  @override
  Future<String> loadString(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }
    return file.readAsString();
  }
}
