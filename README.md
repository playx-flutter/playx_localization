# Playx Localization

[![pub package](https://img.shields.io/pub/v/playx_localization.svg?color=1284C5)](https://pub.dev/packages/playx_localization)
[![Build](https://github.com/playx-flutter/playx_localization/actions/workflows/build.yml/badge.svg)](https://github.com/playx-flutter/playx_localization/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/playx-flutter/playx_localization/graph/badge.svg)](https://codecov.io/gh/playx-flutter/playx_localization)
[![Docs](https://img.shields.io/badge/docs-guides%20%26%20API-1284C5)](https://playx-flutter.github.io/playx_localization/)

Manage the locales of your Flutter app, translate text **without a `BuildContext`**, handle
plurals the way each language needs them, and remember the user's choice.

**Documentation: <https://playx-flutter.github.io/playx_localization/>**

## Features

- **Locale management**: switch by index, id, language code or `XLocale`, follow the device language, reset.
- **Translate anywhere**: `'title'.tr()` works in widgets, view models and plain Dart classes.
- **Real plurals**: Arabic `مركبة` / `مركبتان` / `٣ مركبات` / `١١ مركبة` from one entry, plus Russian, Polish and more. Optional Arabic digits.
- **Persistence**: the selected locale is saved by id and restored, in the storage you choose.
- **Fallbacks**: fallback locale, base-language files (`en-US` → `en`), optional fallback for empty values.
- **Flexible sources**: JSON with nesting and linked files, merged loaders, your own loader, and translations shipped by other packages.
- **Per-call locale**: show one string in English while the app is in Arabic, or skip translation with `translate: false`.
- **Command line tools**: generate typed key constants and validate every locale in CI.
- **Locale utilities**: Arabic/English text helpers, number, currency and date formatting, RTL detection.

## Installation

```yaml
dependencies:
  playx_localization: ^1.0.0
```

Requires Dart 3.12 and Flutter 3.44 or newer.

## Quick start

**1.** Add a JSON file per locale and declare the folder in `pubspec.yaml`:

```plaintext
assets/translations
├── en.json     { "welcome": "Welcome, {name}!", "item": { "one": "{} item", "other": "{} items" } }
└── ar.json
```

```yaml
flutter:
  assets:
    - assets/translations/
```

**2.** Boot it before `runApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const locales = [
    XLocale(id: 'en', name: 'English', languageCode: 'en'),
    XLocale(id: 'ar', name: 'العربية', languageCode: 'ar'),
  ];

  await PlayxLocalization.boot(
    config: PlayxLocaleConfig(
      supportedLocales: locales,
      startLocale: locales.first,
      fallbackLocale: locales.first,
    ),
  );

  runApp(const MyApp());
}
```

**3.** Wrap your app:

```dart
PlayxLocalizationBuilder(
  builder: (context, xLocale) => MaterialApp(
    locale: xLocale.locale,
    supportedLocales: PlayxLocalization.supportedLocales,
    localizationDelegates: PlayxLocalization.localizationDelegates,
    home: const HomePage(),
  ),
)
```

**4.** Translate and switch:

```dart
Text('welcome'.tr(context: context, namedArgs: {'name': 'Sam'}));
Text(context.plural('item', 3));          // 3 items

await PlayxLocalization.updateById('ar'); // saved and restored on the next start
```

For iOS, also list the supported languages in `ios/Runner/Info.plist`, see the
[Flutter docs](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#specifying-supportedlocales).

## Highlights

### Nouns with numbers

```json
"vehicle": {
  "one": "مركبة",
  "two": "مركبتان",
  "few": "{} مركبات",
  "many": "{} مركبة",
  "other": "{} مركبة"
}
```

```dart
'vehicle'.plural(1);                          // مركبة
'vehicle'.plural(2);                          // مركبتان
'vehicle'.plural(3, localizeDigits: true);    // ٣ مركبات
'vehicle'.plural(11, localizeDigits: true);   // ١١ مركبة
```

### A different locale for one key

```dart
'title'.tr(locale: const Locale('en'));
await PlayxLocalization.preloadLocales([const Locale('en')]); // load it once
```

### Translations from other packages

```dart
await PlayxLocalization.registerTranslations(
  PlayxTranslationSource.package(package: 'my_package', namespace: 'my_package'),
);
```

### Typed keys and validation

```bash
dart run playx_localization:generate   # AppTrans.homeTitle.tr()
dart run playx_localization:validate   # missing keys, placeholders, plural forms
```

## Guides

| Guide | What it covers |
|---|---|
| [Getting started](https://playx-flutter.github.io/playx_localization/getting-started) | Install, boot and the first translated screen. |
| [Translation files](https://playx-flutter.github.io/playx_localization/translation-files) | File names, nesting, linked files, fallbacks, custom loaders. |
| [Translating text](https://playx-flutter.github.io/playx_localization/translating-text) | `tr`, arguments, gender, links, a different locale for one key. |
| [Plurals](https://playx-flutter.github.io/playx_localization/plurals) | Plural forms per language, nouns with numbers, Arabic digits. |
| [Switching locales](https://playx-flutter.github.io/playx_localization/switching-locales) | Updating, following the device, resetting. |
| [Persistence](https://playx-flutter.github.io/playx_localization/persistence) | What is saved, custom storage, migration. |
| [Translations from packages](https://playx-flutter.github.io/playx_localization/package-translations) | Let other packages register their own translations. |
| [Command line tools](https://playx-flutter.github.io/playx_localization/command-line-tools) | Generate keys and validate translations. |
| [Configuration](https://playx-flutter.github.io/playx_localization/configuration) | Every `PlayxLocaleConfig` option. |
| [Extensions](https://playx-flutter.github.io/playx_localization/extensions) | String, number, date and locale helpers. |
| [Testing](https://playx-flutter.github.io/playx_localization/testing) | Testing code that uses translations. |
| [Migration](https://playx-flutter.github.io/playx_localization/migration) | Moving from 0.x to 1.0. |

The full [API reference](https://playx-flutter.github.io/playx_localization/api/) is generated from the code.

## Example

A runnable app is in [`example/`](example).

## Contributing

Issues and pull requests are welcome at
[github.com/playx-flutter/playx_localization](https://github.com/playx-flutter/playx_localization).
Before opening a pull request run:

```bash
dart format .
flutter analyze
flutter test --coverage
```

See the [changelog](CHANGELOG.md) for what changed in each release.

## License

See [LICENSE](LICENSE).
