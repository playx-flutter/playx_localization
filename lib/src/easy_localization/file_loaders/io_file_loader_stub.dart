import 'file_loader.dart';

/// Stub File loader implementation for web applications where dart:io is unavailable.
class IOFileLoader implements FileLoader {
  const IOFileLoader();

  @override
  Future<String> loadString(String path) async {
    throw UnsupportedError('dart:io is not supported on the web.');
  }
}
