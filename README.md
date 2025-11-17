# Playx Localization

[![pub package](https://img.shields.io/pub/v/playx_localization.svg?color=1284C5)](https://pub.dev/packages/playx_localization)


Simplify app localization management with Playx Localization. This package offers a straightforward implementation and a wealth of utilities to manage and update app localization effortlessly.

## Features 🔥

-   **Easy Locale Management:** Create and manage app locales with the ability to easily switch between them.
-   **Context-Free Localization:** No need for `BuildContext` anymore, making localization even simpler.
-   **Dart Isolate Support:** Supports Dart isolates for background localization tasks.
-   **Multiple File Formats:** Load translations from JSON, CSV, Yaml, XML, and more.
-   **React to Locale Changes:** Automatically react to and persist locale changes within the app.
-   **Advanced Localization:** Supports plural, gender, nesting, RTL locales, and more.
-   **Fallback Locale Handling:** Define fallback locale keys for seamless localization fallbacks.

## Installation
Integrating **Playx Localization** into your Flutter project is straightforward. Follow these steps:

### Add Dependency
Include the following line in your `pubspec.yaml` file under the `dependencies` section:

```yaml  
playx_localization: ^0.3.1  
``` 

### Add Translation Files
Organize your localization files within a `translations` folder under the `assets` directory. The files should follow a specific naming convention:

```plaintext  
assets  
└── translations  
    ├── {languageCode}.{ext}                  
    └── {languageCode}-{countryCode}.{ext}    
```  

For example:

```plaintext  
assets  
└── translations  
    ├── en.json  
    └── en-US.json   
```  

### Declare Assets Localization
Declare the localization directory in your `pubspec.yaml`:

```yaml  
flutter:  
  assets:  
    - assets/translations/  
```

### Loading Translations from Other Resources
**Playx Localization** supports loading translations from various sources such as JSON, CSV, HTTP, XML, YAML files, etc. For more information, refer to [Easy Localization Loader](https://github.com/aissat/easy_localization_loader).

### Note on iOS
To enable translation on iOS devices, add supported locales to `ios/Runner/Info.plist` as described [here](https://flutter.dev/docs/development/accessibility-and-localization/internationalization#specifying-supportedlocales).

## Usage
Utilizing **Playx Localization** in your app involves a few simple steps:

### 🔥Boot Core
Initialize the Playx core package with your desired locale configuration:

```dart    
void main() async {    
	WidgetsFlutterBinding.ensureInitialized();
  
  // Define your supported locales and other configurations
	const locales = [  
	  XLocale(id: 'en', name: 'English', languageCode: 'en'),  
	  XLocale(id: 'ar', name: 'العربية', languageCode: 'ar'),  
	];  
  
	final config = PlayxLocaleConfig(  
	  supportedLocales: locales,  
	  startLocale: locales.first,  
	  fallbackLocale: locales.first,  
	  useFallbackTranslations: true,  
	);
	 // Boot Playx Localization with the defined configuration
	 await PlayxLocalization.boot(config: config);

	 runApp(const MyApp());
}
```

### 🔥 Use `PlayxLocalizationBuilder` Widget
Wrap your `MaterialApp` or `CupertinoApp` with the `PlayxLocalizationBuilder` widget to listen to locale changes:

```dart
class MyApp extends StatelessWidget {    
  const MyApp({Key? key});    
    
  @override    
  Widget build(BuildContext context) {  
    return PlayxLocalizationBuilder(builder: (context, locale) {  
      return MaterialApp(  
        supportedLocales: PlayxLocalization.supportedLocales,  
        localizationsDelegates: PlayxLocalization.localizationDelegates,  
        locale: locale.locale,  
        home: const MyHomePage(),  
      );  
    });  
   }    
 }  
```

### 🔥 PlayxLocaleConfig Properties
Configure your localization preferences using the `PlayxLocaleConfig` properties:

| Property                 | Required | Default                  | Description                                                                                                                                                                   |  
| ------------------------ | -------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |  
| supportedLocales         | true     |                          | List of supported locales.                                                                                                                                                    |  
| path                     | false    | 'assets/translations'    | Path to the folder containing localization files.                                                                                                                                  |  
| assetLoader              | false    | `RootBundleAssetLoader()`| Loader for localization files. You can use custom loaders or the default loader provided.                        |  
| fallbackLocale           | false    |                          | The fallback locale used when the desired locale is not available in the supported locales list.                                                                                                   |  
| startLocale              | false    |                          | The initial locale when the app starts. If null, it uses the device locale.                                                                                                                                                   |  
| saveLocale               | false    | `true`                   | Save the chosen locale in the device's storage.                                                                                                                                                |  
| useFallbackTranslations | false    | `true`                   | Use fallback translations if a localization key is not found in the locale file.                                                                                               |  
| useOnlyLangCode          | false    | `false`                  | Use only language code for reading localization files.                                                                                                                         |  

### Update App Locale
Switch between locales using the `PlayxLocalization` facade:

```dart     
FloatingActionButton.extended(  
  onPressed: () {  
    PlayxLocalization.updateByIndex(  
      PlayxLocalization.isCurrentLocaleArabic() ? 0 : 1
    );  
  },  
  label: Text('change_language'.tr),  
  icon: const Icon(Icons.update),  
)  
```   


### 🔥 Translate `tr()`

#### The package uses [`Easy Localization`](https://pub.dev/packages/easy_localization) under the hood to manage translations and Plurals as below.

Retrieve localized text using:

-   `'text'.tr(context: context)`
-   `context.tr()`
-   `Text('text').tr(context: context)`

```dart
Text('title').tr(context:context) //Text widget  
  
print('title'.tr(context:context)); //String  

var title = tr('title',context:context) // Static function  
  
Text(context.tr('title')) //Extension on BuildContext` 
```

Providing context to the `tr` function ensures widgets are rebuilt correctly when the locale changes.  
For classes without context, you can still use the `tr` function without context, though note that widgets will not rebuild on locale changes when used this way, But there is an option to force app update on locale change.

#### Arguments:
Pass arguments to the `tr()` function for dynamic translations:

| Name      | Type                | Description                                                                         |  
| --------- | ------------------- | ----------------------------------------------------------------------------------- |  
| args      | `List<String>`      | List of localized strings. Replaces `{}` left to right                              |  
| namedArgs | `Map<String, String>` | Map of localized strings. Replaces the name keys `{key_name}` according to its name |  
| gender    | `String`            | Gender switcher. Changes the localized string based on gender string                |  

Example:

```json  
{  
   "msg": "{} are written in the {} language",  
   "msg_named": "Playx localization is written in the {lang} language",  
   "msg_mixed": "{} are written in the {lang} language",  
   "gender": {  
      "male": "Hi man ;) {}",  
      "female": "Hello girl :) {}",  
      "other": "Hello {}"  
   }  
}  
```  
Use it like this:

```dart  
// args  
Text('msg').tr(args: ['Playx localization', 'Dart']),  
  
// namedArgs  
Text('msg_named').tr(namedArgs: {'lang': 'Dart'}),  
  
// args and namedArgs  
Text('msg_mixed').tr(args: ['Playx localization'], namedArgs: {'lang': 'Dart'}),  
  
// gender  
Text('gender').tr(gender: _gender ? "female" : "male"),  
  
```

### 🔥 Plurals `plural()`

You can translate with pluralization.  
To insert a number in the translated string, use `{}`. Number formatting supported, for more information read [NumberFormat](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html) class documentation.

You can use extension methods of [String] or [Text] widget, you can also use `plural()` as a static function.

#### Arguments:

| Name      | Type                  | Description                                                                                                                  |  
| --------- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------- |  
| value     | `num` | Number value for pluralization                                                                                               |  
| args      | `List<String>` | List of localized strings. Replaces `{}` left to right                                                                       |  
| namedArgs | `Map<String, String>` | Map of localized strings. Replaces the name keys `{key_name}` according to its name                                          |  
| name      | `String` | Name of number value. Replaces `{$name}` to value                                                                            |  
| format    | `NumberFormat` | Formats a numeric value using a [NumberFormat](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html) class |  

Example:

``` json{  
  "day": {  
    "zero":"{} дней",  
    "one": "{} день",  
    "two": "{} дня",  
    "few": "{} дня",  
    "many": "{} дней",  
    "other": "{} дней"  
  },  
  "money": {  
    "zero": "You not have money",  
    "one": "You have {} dollar",  
    "many": "You have {} dollars",  
    "other": "You have {} dollars"  
  },  
  "money_args": {  
    "zero": "{} has no money",  
    "one": "{} has {} dollar",  
    "many": "{} has {} dollars",  
    "other": "{} has {} dollars"  
  },  
  "money_named_args": {  
    "zero": "{name} has no money",  
    "one": "{name} has {money} dollar",  
    "many": "{name} has {money} dollars",  
    "other": "{name} has {money} dollars"  
  }  
}  
```  
⚠️ Key "other" required!

```dart  
//Text widget with format  
Text('money').plural(1000000, format: NumberFormat.compact(locale: context.locale.toString())) // output: You have 1M dollars  
  
//String  
print('day'.plural(21)); // output: 21 день  
  
//Static function  
var money = plural('money', 10.23) // output: You have 10.23 dollars  
  
//Text widget with plural BuildContext extension  
Text(context.plural('money', 10.23))  
  
//Static function with arguments  
var money = plural('money_args', 10.23, args: ['John', '10.23'])  // output: John has 10.23 dollars  
  
//Static function with named arguments  
var money = plural('money_named_args', 10.23, namedArgs: {'name': 'Jane', 'money': '10.23'})  // output: Jane has 10.23 dollars  
var money = plural('money_named_args', 10.23, namedArgs: {'name': 'Jane'}, name: 'money')  // output: Jane has 10.23 dollars  
```  

### 🔥 Linked translations:

If there's a translation key that will always have the same concrete text as another one you can just link to it. To link to another translation key, all you have to do is to prefix its contents with an `@:` sign followed by the full name of the translation key including the namespace you want to link to.

Example:
```json  
{  
  "example": {  
  "hello": "Hello",  
    "world": "World!",  
    "helloWorld": "@:example.hello @:example.world"  
  }  
}  
```  

```dart  
print('example.helloWorld'.tr); //Output: Hello World!  
```  

You can also do nested anonymous and named arguments inside the linked messages.

Example:

```json  
{  
  "date": "{currentDate}.",  
  "dateLogging": "INFO: the date today is @:date"  
}  
```  
```dart  
print(tr('dateLogging', namedArguments: {'currentDate': DateTime.now().toIso8601String()})); //Output: INFO: the date today is 2020-11-27T16:40:42.657.  
```  

#### Formatting linked translations:

Formatting linked locale messages  
If the language distinguishes cases of character, you may need to control the case of the linked locale messages. Linked messages can be formatted with modifier `@.modifier:key`

The below modifiers are available currently.

- `upper`: Uppercase all characters in the linked message.
- `lower`: Lowercase all characters in the linked message.
- `capitalize`: Capitalize the first character in the linked message.

Example:

```json  
{  
  "example": {  
  "fullName": "Full Name",  
    "emptyNameError": "Please fill in your @.lower:example.fullName"  
  }  
}  
```  

Output:

```dart  
print('example.emptyNameError'.tr); //Output: Please fill in your full name  
```  

### 🔥 Get device locale `deviceLocale`

Get device locale

Example:

```dart  
print(${PlayxLocalization.deviceLocale.toString()}) // OUTPUT: en_US  
```  

### 🔥 Delete save locale `deleteSaveLocale()`

Clears a saved locale from device storage

Example:

```dart  
RaisedButton(  
  onPressed: (){  
    PlayxLocalization.deleteSaveLocale();  
  },  
  child: Text(LocaleKeys.reset_locale).tr(),  
)  
```  


### 🔥``PlayxLocalization`` available methods :

| Method           | Description                                                |  
| -----------      | :--------------------------------------------------------  |  
| currentIndex     | Get current `XLocale` index.                                |  
| currentXLocale   | Get current `XLocale`.                                      |   
| currentLocale    | Get current locale.                                    |  
| deviceLocale     | Get current device locale.                                      |  
| nextLocale       | updates the app locale to the next locale .                   |  
| updateByIndex    | updates the app locale by the index.                        |  
| updateById       | updates the app locale by the `XLocale` id.                        |  
| updateTo         | updates the app locale to a specific `XLocale`.              |  
| updateToDeviceLocale | Updates the app locale to current device locale.              |  
| updateByLanguageCode | updates the app locale by language code and country code if available              |  
| supportedXLocales| Get current supported x locales configured in `XLocaleConfig `. |  
| supportedLocales| Get current supported locales of `supportedXLocales`.                         |  
| isCurrentLocaleArabic| Check if current locale is arabic.                         |                       |  
| isCurrentLocaleEnglish| Check if current locale is english.                        |  
| isCurrentLocaleRtl| Check if current locale is rtl.                         |  
| currentLocaleToString| Convert current [locale] to String with custom [separator] representing language.    
| deleteSavedLocale| Deletes saved locale from device storage.                         |  


### 🔥 Extensions & utilities

The package include other extensions and utitlies that can be helpful for development.

For Example:

#### Convert Date to formated and localized String using:

```dart  
  final dateText = DateTime.now().toFormattedDate(  
      format: 'yyyy-MM-dd',  
      locale: PlayxLocalization.currentLocale.toStringWithSeparator());  
  
  print('Curent date: $dateText');  
```  

#### There is also other extensions on nubmer
| Method           | Description                                                |  
| -----------      | :--------------------------------------------------------  |  
| roundToPrecision     | Extension function to round number to certain number.   |  
| toFormattedCurrencyNumber   | Extension function to format number to currency number.     |   
| toFormattedNumber    | Extension function to format number to  String.           |  




## Documentation && References

- [Easy Localization](https://pub.dev/packages/easy_localization), The app uses the easy localization package under the hood to load translations.
- [Documentaion](https://pub.dev/packages/playx_localization#documentation--references)


## See Also:
[Playx](https://pub.dev/packages/playx) : Playx eco system helps with redundant features , less code , more productivity , better organizing.

[playx_core](https://pub.dev/packages/playx_core) : core package of playx.

[playx_theme](https://pub.dev/packages/playx_theme) : Multi theme features for flutter apps from playx eco system.

[playx_widget](https://pub.dev/packages/playx_widget) : PlayX widget package for playx eco system that provide custom utility widgets to make development faster.

[playx_version_update](https://pub.dev/packages/playx_version_update) : Easily show material update dialog in Android or Cupertino dialog in IOS with support for Google play in app updates.

[playx_network](https://pub.dev/packages/playx_network) :  Wrapper around Dio that can perform api request with better error handling and easily get the result of any api request.