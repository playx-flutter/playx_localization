import 'dart:io';

import 'cli_args.dart';
import '../easy_localization/plural_rules.dart';
import 'key_generator.dart';
import 'translation_files.dart';

enum IssueSeverity { error, warning }

class ValidationIssue {
  final IssueSeverity severity;
  final String locale;
  final String key;
  final String message;

  const ValidationIssue(this.severity, this.locale, this.key, this.message);

  @override
  String toString() =>
      '${severity.name}: [$locale] ${key.isEmpty ? '' : '$key: '}$message';
}

final _placeholder = RegExp(r'\{(\w*)\}');

/// Placeholder name -> occurrences. `{}` is stored under the empty name.
Map<String, int> placeholdersOf(String value) {
  final out = <String, int>{};
  for (final m in _placeholder.allMatches(value)) {
    out.update(m[1]!, (n) => n + 1, ifAbsent: () => 1);
  }
  return out;
}

String _describe(Map<String, int> p) => p.isEmpty
    ? 'none'
    : (p.entries
            .map((e) => '{${e.key}}${e.value > 1 ? ' x${e.value}' : ''}')
            .toList()
          ..sort())
        .join(', ');

bool _samePlaceholders(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

/// Plural groups that lack the mandatory `other` form.
List<String> _pluralGroupsWithoutOther(Map<String, dynamic> data,
    [String prefix = '']) {
  final out = <String>[];
  data.forEach((key, value) {
    if (value is! Map<String, dynamic>) return;
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value.isNotEmpty &&
        value.keys.every(pluralForms.contains) &&
        value.values.every((v) => v is String) &&
        !value.containsKey('other')) {
      out.add(path);
    } else {
      out.addAll(_pluralGroupsWithoutOther(value, path));
    }
  });
  return out;
}

/// Plural groups (`{"one": ..., "other": ...}`) by key path with their forms.
Map<String, Set<String>> _pluralGroups(Map<String, dynamic> data,
    [String prefix = '']) {
  final out = <String, Set<String>>{};
  data.forEach((key, value) {
    if (value is! Map<String, dynamic>) return;
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value.isNotEmpty &&
        value.keys.every(pluralForms.contains) &&
        value.values.every((v) => v is String)) {
      out[path] = value.keys.toSet();
    } else {
      out.addAll(_pluralGroups(value, path));
    }
  });
  return out;
}

/// Compares [locales] (locale -> loaded data) against [baseLocale].
List<ValidationIssue> validateTranslations({
  required String baseLocale,
  required Map<String, Map<String, dynamic>> locales,
}) {
  final issues = <ValidationIssue>[];
  final base = flattenTranslations(locales[baseLocale]!);

  for (final entry in locales.entries) {
    final locale = entry.key;
    final data = entry.value;
    final flat = flattenTranslations(data);

    for (final key in _pluralGroupsWithoutOther(data)) {
      issues.add(ValidationIssue(IssueSeverity.error, locale, key,
          'plural group is missing the required "other" form'));
    }

    // Forms the language needs, e.g. Arabic `few` and `many`. `zero` is
    // optional because it falls back to `other`.
    final language = locale.split(RegExp('[-_]')).first;
    final needed = pluralCategoriesFor(language)
        .map((c) => c.name.toLowerCase())
        .toSet()
      ..removeAll(const {'other', 'zero'});
    _pluralGroups(data).forEach((path, forms) {
      final missing = needed.difference(forms);
      if (missing.isEmpty) return;
      issues.add(ValidationIssue(
          IssueSeverity.warning,
          locale,
          path,
          'plural group has no ${(missing.toList()..sort()).join(', ')} '
          'form, which the "$language" plural rules use '
          '(it falls back to "other")'));
    });

    for (final e in flat.entries) {
      if (e.value.trim().isEmpty) {
        issues.add(ValidationIssue(
            IssueSeverity.warning, locale, e.key, 'value is empty'));
      }
    }

    if (locale == baseLocale) continue;

    for (final key in base.keys) {
      if (!flat.containsKey(key)) {
        issues.add(ValidationIssue(
            IssueSeverity.error, locale, key, 'missing (present in $baseLocale)'));
      }
    }
    for (final key in flat.keys) {
      if (!base.containsKey(key)) {
        issues.add(ValidationIssue(IssueSeverity.warning, locale, key,
            'not present in $baseLocale'));
      }
    }
    for (final key in base.keys.where(flat.containsKey)) {
      final expected = placeholdersOf(base[key]!);
      final actual = placeholdersOf(flat[key]!);
      if (!_samePlaceholders(expected, actual)) {
        issues.add(ValidationIssue(
            IssueSeverity.error,
            locale,
            key,
            'placeholders differ from $baseLocale '
            '(expected ${_describe(expected)}, found ${_describe(actual)})'));
      }
    }
  }
  return issues;
}

/// Keys of the base locale that are not referenced from Dart sources in
/// [srcDir]: neither as a string literal nor through a generated constant.
List<String> findUnusedKeys(Iterable<String> keys, String srcDir) {
  final dir = Directory(srcDir);
  if (!dir.existsSync()) return [];
  final contents = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.readAsStringSync())
      // Skip files made by the key generator, they mention every key.
      .where((s) => !s.contains('Generated by `dart run playx_localization:generate`'))
      .toList();
  final source = contents.join('\n');

  return keys.where((key) {
    final literal = RegExp('[\'"]${RegExp.escape(key)}[\'"]');
    final constant = RegExp(r'\.' + keyToIdentifier(key) + r'\b');
    return !literal.hasMatch(source) && !constant.hasMatch(source);
  }).toList();
}

const validateUsage = '''
Checks translation files for missing keys, placeholder mismatches and more.

Usage: dart run playx_localization:validate [options]

  --dir <dir>       Translations directory (default: assets/translations)
  --base <locale>   Locale used as the reference (default: en)
  --src <dir>       Also report base keys never used in Dart code under <dir>
  --strict          Treat warnings as errors
  --help            Show this help

Errors: missing keys, placeholder mismatches, plural groups without "other",
unreadable files or broken linked files.
Warnings: extra keys, empty values, unused keys, plural groups missing forms
the language uses (e.g. Arabic few/many).
''';

/// Entry point of `validate`. Returns the process exit code.
Future<int> runValidate(List<String> args,
    {StringSink? out, StringSink? err}) async {
  out ??= stdout;
  err ??= stderr;
  final cli = CliArgs.parse(args, flagNames: {'strict', 'help'});
  if (cli.has('help')) {
    out.write(validateUsage);
    return 0;
  }
  final dir = cli['dir'] ?? 'assets/translations';
  final baseLocale = cli['base'] ?? 'en';

  final files = findTranslationFiles(dir);
  if (files.isEmpty) {
    err.writeln('No translation files found in $dir');
    return 66;
  }
  if (!files.any((f) => f.locale == baseLocale)) {
    err.writeln('Base locale "$baseLocale" not found in $dir '
        '(found: ${files.map((f) => f.locale).join(', ')}). Use --base.');
    return 66;
  }

  final issues = <ValidationIssue>[];
  final loaded = <String, Map<String, dynamic>>{};
  for (final file in files) {
    try {
      loaded[file.locale] = await file.load();
    } on FormatException catch (e) {
      issues.add(ValidationIssue(IssueSeverity.error, file.locale, '',
          'invalid JSON (${e.message})'));
    } catch (e) {
      issues.add(ValidationIssue(
          IssueSeverity.error, file.locale, '', e.toString()));
    }
  }

  if (loaded.containsKey(baseLocale)) {
    issues.addAll(validateTranslations(baseLocale: baseLocale, locales: loaded));
    final src = cli['src'];
    if (src != null) {
      final base = flattenTranslations(loaded[baseLocale]!);
      for (final key in findUnusedKeys(base.keys, src)) {
        issues.add(ValidationIssue(
            IssueSeverity.warning, baseLocale, key, 'unused in $src'));
      }
    }
  }

  for (final issue in issues) {
    out.writeln(issue);
  }
  final errors = issues.where((i) => i.severity == IssueSeverity.error).length;
  final warnings = issues.length - errors;
  out.writeln('Checked ${files.length} locales: $errors errors, $warnings warnings.');

  return errors > 0 || (cli.has('strict') && warnings > 0) ? 1 : 0;
}

