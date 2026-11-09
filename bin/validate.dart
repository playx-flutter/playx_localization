import 'dart:io';

import 'package:playx_localization/src/tools/translation_validator.dart';

Future<void> main(List<String> args) async {
  exitCode = await runValidate(args);
}
