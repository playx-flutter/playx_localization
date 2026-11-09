/// Minimal `--name value` / `--name=value` / `--flag` parser, so the command
/// line tools need no extra dependencies.
class CliArgs {
  final Map<String, String> options = {};
  final Set<String> flags = {};
  final List<String> rest = [];

  CliArgs.parse(List<String> args, {Set<String> flagNames = const {}}) {
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) {
        rest.add(arg);
        continue;
      }
      final body = arg.substring(2);
      final eq = body.indexOf('=');
      if (eq != -1) {
        options[body.substring(0, eq)] = body.substring(eq + 1);
      } else if (flagNames.contains(body)) {
        flags.add(body);
      } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        options[body] = args[++i];
      } else {
        flags.add(body);
      }
    }
  }

  String? operator [](String name) => options[name];
  bool has(String flag) => flags.contains(flag);
}
