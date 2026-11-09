# Changelog

## 1.0.0
> **Note**: First stable release. Raises the minimum supported SDK versions (Dart 3.12, Flutter 3.44). Existing saved locales, translation files named in the old script-code order, and linked-file folders are migrated automatically; see the entries below.

- **Breaking**: Requires Dart `>=3.12.0` and Flutter `>=3.44.0`.
- Updated `playx_core` dependency to `^2.0.0` and upgraded all dependencies to their latest versions.
- **Translations from other packages**: Added `PlayxLocalization.registerTranslations` / `unregisterTranslations` and `PlayxTranslationSource` (with a `.package` constructor) so packages can ship their own translations. Supports optional key `namespace`, works before or after boot, tolerates missing locales, and is always overridden by the app's own keys.
- **Key generator**: New `dart run playx_localization:generate` command generates a class of typed key constants from a base translation file (nested keys, linked files, plural groups, `--check` for CI).
- **Validator**: New `dart run playx_localization:validate` command reports missing/extra keys, placeholder mismatches, plural groups without `other`, empty values, unused keys (`--src`), invalid JSON and broken linked files. Exits non-zero on errors (or warnings with `--strict`).
- **Script code naming follows BCP-47 (with migration)**: Locales with both a script and a country code are now written `language-script-country` (e.g. `zh-Hant-TW`) by `Locale.toStringWithSeparator`, matching `Locale.toLanguageTag()`. Translation files are looked up as `zh-Hant-TW.json` first, then as the old `zh-TW-Hant.json` (with a log message to rename it). Linked files are looked up in the `zh-Hant-TW/` folder first, then in the old `zh-TW/` folder that ignored the script. Locales without a script, or without a country, are unchanged. Added `Locale.toLegacyStringWithSeparator`. The command line tools understand both file name orders.
- **Note for custom `LinkedFileResolver` subclasses**: `resolveLinkedFiles` has a new optional `scriptCode` parameter.
- **Fix**: `DateTime.toFormattedDate` / `toFormattedTime` used only the language code, so `de-AT` got `de` month names. They now use the full locale tag (still overridable with `locale`).
- **`translate` option**: `tr` and `plural` (String, `Text` and `BuildContext` variants) accept `translate: false` to return the text as-is, still applying `args` / `namedArgs`.
- **`preloadLocales`**: New `PlayxLocalization.preloadLocales` loads only the locales you need so `tr(locale: ...)` works for them without enabling `preloadSupportedLocales` for all locales.
- `tr` with a `BuildContext` now falls back to the global instance when no `Localization` is found in the context, instead of throwing.
- **Locale saved by id (with migration)**: The selected locale is now saved by its `XLocale.id` instead of its position in `supportedLocales`, so reordering, inserting or removing locales in an app update no longer restores the wrong language. Existing installs migrate automatically: a saved index is read when no id exists yet, then rewritten as an id (the index is still written, so downgrades keep working). A saved locale that was removed falls back to `startLocale` / the device locale instead of a different language. The device-sync flag (`-1`) keeps working.
- **Pluggable storage**: Added `PlayxLocaleConfig.storage` with `PlayxLocaleStorage`, `PlayxPrefsLocaleStorage` (default) and `PlayxMemoryLocaleStorage`, like `playx_theme`. Writes are queued so the last requested locale is always the last one saved.
- **`resetLocale` forgets the saved choice**: it now clears the saved locale and applies the fresh-install locale (`startLocale`, device, fallback) without saving it. Before, it saved that result as an explicit choice.
- `getLastSavedIndexFromPrefs` is deprecated.
- **Fix**: `config.useFallbackTranslations` was ignored; the fallback locale was always loaded. It is now respected.
- **Fix**: A failed locale switch (for example a missing translation file) no longer wipes the loaded translations, changes the locale or saves it. `updateTo`, `updateById`, etc. now return `false` and keep the current locale. `loadTranslations` now returns a `bool`.
- **Fix**: One missing or broken locale file no longer breaks `preloadSupportedLocales` for all locales.
- **Fix**: Looking up a key that points to a group (e.g. `'home'` when `home` is an object) crashed; a path through a text value (`'a.b.c'` where `a.b` is text) returned the wrong text. Both now behave like a missing key.
- **Fix**: `namedArgs` whose names contain regex characters (e.g. `{a.b}`, `{x+y}`) were not replaced.
- **Fix**: `@:key` links are now resolved in the locale passed to `tr(locale: ...)` instead of the current locale, and the `@.capitalize:` modifier no longer crashes on empty text.
- **Fix**: `PlayxLocalization.currentLocaleToString` was not `static`, so it could not be called. `PlayxLocalization.updateByLanguageCode` now accepts `scriptCode`.
- **Fix**: `context.isCurrentLocaleRtl` / `isCurrentLocaleLtr` always reported LTR because they analyzed the language code as text.
- **Fix**: `Text(...).tr()` and `.plural()` dropped the original `Text.locale`.
- The optional base-language fallback file (e.g. `en` for `en-US`) is now merged recursively and any load failure for it is ignored.
- **Fix**: Linking the same translation file from multiple keys is no longer reported as a cyclic link. Only real cycles throw now.
- Added a unit test suite covering plural rules, translations, linked file resolution, translation merging, device-sync persistence, `scriptCode` locale matching, and the string, number and locale extensions.
- Fixed analyzer lints.

## 0.4.0
- **Enhanced Locale Config**: Added `useFallbackTranslationsForEmptyResources`, `ignorePluralRules`, `extraAssetLoaders`, and `errorWidget` to `PlayxLocaleConfig`.
- **Script Code Support**: Added `scriptCode` natively to `XLocale` and updated locale matching in `PlayxLocaleController` to properly utilize it.
- **Deep Translation Merging**: `TranslationManager` now supports combining JSON translation maps securely from multiple asset loaders.
- **Device Sync Persistence**: `updateToDeviceLocale()` now saves a special flag in preferences (index `-1`). When the application boots, instead of overriding the device's current locale with a historically cached exact locale or `startLocale`, the controller auto-routes strictly to whatever the current `deviceLocale` dictates. This allows developers to offer a persistent "system default" setting.
- **Synchronous Any-Locale Translation**: Added `preloadSupportedLocales` to `PlayxLocaleConfig`. When enabled, it caches all dictionaries during initialization, allowing developers to query translations for any loaded `Locale? locale` parametrically using `tr(..., locale: ...)` synchronously, completely out-of-bounds, without overriding the app environment.

## 0.3.1
- Bumping `playx_core` dependency to `^0.7.4`.
- Renaming `isRtl` and `isLtr` getters to `isCurrentLocaleRtl` and `isCurrentLocaleLtr` respectively for better clarity.
- Allow passing BuildContext to plural for locale-aware formatting


## 0.3.0

### Enhancements

* **Improved Delegate Configuration**:

    * Added `extraDelegates` to inject custom localization delegates.
    * Added `customLocalizationDelegateBuilder` to fully customize the delegate list.
* **Logging Enhancements**:

    * Added `logLocaleChanges` toggle in `PlayxLocaleConfig`.
    * Improved logs to show locale name, value, and index.

* Removed `easy_localization` dependency; replaced with a custom, flexible system.

### New Extensions

####  `BuildContext` Locale Helpers

* Easily access locale info like `currentLocale`, `localeTag`, `languageCode`, `isRtl`, `fontFamily`, and more.

#### Number Extensions

* Enhanced currency formatting with `toFormattedCurrencyNumber` and `toLocalizedCurrencyNumber`.
* Added format options to all localized number methods.
* New `isZero` utility for floating-point comparisons.

#### String Localization Extensions

* Check for RTL/LTR, Arabic/English text, numbers, and diacritics.
* Convert digits between Arabic and Western formats.
* Normalize Arabic letters and clean up extra spaces.

#### Locale Utilities

* New extensions for `Locale`, `XLocale`, and `String` for parsing and formatting.


## 0.2.2
- Update packages.

## 0.2.1
- Update packages.
- Add new parameter `fontFamily` to `XLocale` to set the font family for the localized text for each locale.
- `logMissingKeys` parameter is now set to `false` by default.
- Add new extension `toFormattedTime` on `DateTime` to format time to localized time string.


## 0.2.0
> **Note**: This release contains breaking changes.

- Migrated shared preferences to `SharedPreferencesAsync` for improved performance and async handling.  If you're upgrading, set `migratePrefsToAsyncPrefs` to `true` in `PlayxLocaleConfig` to ensure a smooth transition.
- Add new `logMissingKeys` parameter to `PlayxLocaleConfig` to enable or disable logging missing keys in the console.
- Removed dependencies on GetX package.
- No need to call `await PlayXCore.bootCore();` before using the localization package anymore. The package will automatically initialize the core when needed.

## 0.1.2
- Fix bug causing locale to not be saved correctly.

## 0.1.1
- enhance log messages.

## 0.1.0
> **Note**: This release contains breaking changes.

### New Features

#### General Updates
- **Package Updates**: All packages have been updated.
- **`intl` Package**: Upgraded to version 0.19.0.

#### PlayxLocalizationBuilder
- **Improved Locale Management**: Now uses an `InheritedWidget` to provide locale to child widgets, enhancing locale management and widget rebuilds.
- **Simplified Localization Access**:
    - Retrieve localized text using:
        - `'text'.tr(context: context)`
        - `context.tr()`
        - `Text('text').tr(context: context)`
    - New `BuildContext` extensions: `context.tr()` and `context.plural` for easy access to localized text.

  Providing context to the `tr` function ensures widgets are rebuilt correctly when the locale changes. 
- For classes without context, you can still use the `tr` function without context, though note that widgets will not rebuild on locale changes when used this way, But there is an option to force app update on locale change.

#### PlayxLocalization
- Added a getter to retrieve the app's fallback locale.
-  Added a function to get the current locale as a string with a custom separator.
- Added a function to determine if the current locale is right-to-left (RTL).

#### PlayxLocaleController
-  Switched from `GetxController` to `ValueNotifier`, reducing reliance on the `GetX` package.
-  Updated methods (`updateTo`, `updateByIndex`, `updateById`, `next`, `updateByLanguageCode`, `updateToDeviceLocale`) now include a `forceAppUpdate` parameter to allow a full app rebuild when changing the locale.

### Breaking Changes
-  `XLocaleConfig` has been renamed to `PlayxLocaleConfig` to align with the package name.
-`PlayxLocaleConfig` is no longer abstract and can be instantiated directly.
-  `PlayxLocaleConfig` now requires default and supported locales to be provided at instantiation.
-  The `tr` extension on `String` has been updated to a function that accepts context and additional parameters.

## 0.0.5
- Update packages.

## 0.0.4
- Update packages.
- Bump Intl version to 0.18.1.


## 0.0.3

- Update packages.
- Bump dart version to 3.0.0.
- Add number extensions for `num` to format number to localized numbers String like arabic numbers.
- Add `String` extensions to check if string is rtl or is of specifc language.

## 0.0.2

- Update packages.


## 0.0.1

- Initial release.
