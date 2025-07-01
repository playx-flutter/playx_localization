import 'package:flutter/material.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/widgets/playx_inherited_localization.dart';

/// PlayxLocalizationBuilder:
/// It allows us to create a widget with current locale.
/// It should rebuild the widget automatically after changing the locale.
class PlayxLocalizationBuilder extends StatelessWidget {
  /// The builder function that will be called when the locale changes.
  final Widget Function(
    BuildContext context,
    XLocale xLocale,
  ) builder;

  const PlayxLocalizationBuilder({super.key, required this.builder});

  PlayxLocaleController get controller => PlayxLocaleController.controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, XLocale? xLocale, child) {
        if (xLocale == null) {
          throw Exception(
              'Localization has not been initialized. You must call boot method before accessing any property.');
        }
        return PlayxInheritedLocalization(
          locale: xLocale,
          child: Localizations(
              locale: xLocale.locale,
              delegates: controller.delegates,
              child: builder(context, xLocale)),
        );
      },
    );
  }
}
