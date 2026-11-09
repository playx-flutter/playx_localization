---
title: Home
layout: home
nav_order: 1
---

# Playx Localization

Manage the locales of your Flutter app, load and translate text without a
`BuildContext`, handle plurals the way each language needs them, and remember the
user's choice.

- **Locale management**: any number of locales, switch by index, id, language code or `XLocale`.
- **Translate anywhere**: `'title'.tr()` works in widgets, view models and plain Dart classes.
- **Real plurals**: Arabic `مركبة` / `مركبتان` / `٣ مركبات` / `١١ مركبة` from a single entry, plus Russian, Polish and more.
- **Persistence**: the selected locale is saved by id and restored, in the storage you choose. Following the device language is a saved choice too.
- **Fallbacks**: fallback locale, base-language files (`en-US` → `en`) and optional per-key fallbacks.
- **Flexible sources**: JSON files, linked files, several loaders merged together, your own loader, and translations shipped by other packages.
- **Per-call locale**: show one string in English while the app is in Arabic.
- **Command line tools**: generate typed key constants and validate every locale in CI.

[Get started]({{ site.baseurl }}/getting-started){: .btn .btn-primary }
[API reference]({{ site.baseurl }}/api/){: .btn }

## Requirements

| | Minimum |
|---|---|
| Dart | 3.12 |
| Flutter | 3.44 |

## Install

```yaml
dependencies:
  playx_localization: ^1.0.0
```

## Guides

| Guide | What it covers |
|---|---|
| [Getting started]({{ site.baseurl }}/getting-started) | Install, boot and the first translated screen. |
| [Translation files]({{ site.baseurl }}/translation-files) | File names, nesting, linked files, fallbacks, custom loaders. |
| [Translating text]({{ site.baseurl }}/translating-text) | `tr`, arguments, gender, links, a different locale for one key. |
| [Plurals]({{ site.baseurl }}/plurals) | Plural forms per language, nouns with numbers, Arabic digits. |
| [Switching locales]({{ site.baseurl }}/switching-locales) | Updating the locale, following the device, resetting. |
| [Persistence]({{ site.baseurl }}/persistence) | What is saved, custom storage, migration. |
| [Translations from packages]({{ site.baseurl }}/package-translations) | Let other packages register their own translations. |
| [Command line tools]({{ site.baseurl }}/command-line-tools) | Generate keys and validate translations. |
| [Configuration]({{ site.baseurl }}/configuration) | Every `PlayxLocaleConfig` option. |
| [Extensions]({{ site.baseurl }}/extensions) | String, number, date and locale helpers. |
| [Testing]({{ site.baseurl }}/testing) | Testing code that uses translations. |
| [Migration]({{ site.baseurl }}/migration) | Moving from 0.x to 1.0. |
