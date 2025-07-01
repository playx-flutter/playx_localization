import 'package:flutter/material.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';

import '../easy_localization/localization.dart';

///The delegates for this app's Localizations widget.
///
/// The delegates collectively define all of the localized resources for this application's Localizations widget
class PlayxLocalizationDelegate extends LocalizationsDelegate<Localization> {
  final List<XLocale>? supportedLocales;
  final PlayxLocaleController? localizationController;

  ///  * use only the lang code to generate i18n file path like en.json or ar.json
  // final bool useOnlyLangCode;

  PlayxLocalizationDelegate(
      {this.localizationController, this.supportedLocales});

  @override
  bool isSupported(Locale locale) =>
      supportedLocales!.any((xLocale) => xLocale.locale == locale);

  @override
  Future<Localization> load(Locale locale) async {
    if (localizationController!.translations == null) {
      final xLocale = localizationController!.searchLocaleByLanguageCode(
          languageCode: locale.languageCode, countryCode: locale.countryCode);
      if (xLocale == null) {
        throw UnsupportedError('Locale not found');
      }
      await localizationController!.loadTranslations(xLocale);
    }
    Localization.load(locale,
        translations: localizationController!.translations,
        fallbackTranslations: localizationController!.fallbackTranslations);

    return Future.value(Localization.instance);
  }

  @override
  bool shouldReload(LocalizationsDelegate<Localization> old) => false;
}
