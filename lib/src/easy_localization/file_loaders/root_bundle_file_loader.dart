import 'package:flutter/services.dart';

import 'file_loader.dart';

/// File loader implementation for Flutter applications using rootBundle
class RootBundleFileLoader implements FileLoader {
  const RootBundleFileLoader();

  @override
  Future<String> loadString(String path) async {
    return rootBundle.loadString(path);
  }
}
