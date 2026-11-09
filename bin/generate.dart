import 'dart:io';

import 'package:playx_localization/src/tools/key_generator.dart';

Future<void> main(List<String> args) async {
  exitCode = await runGenerate(args);
}
