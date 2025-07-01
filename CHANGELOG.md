# Changelog

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
