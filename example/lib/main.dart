import 'package:flutter/material.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization_example/translation/app_trans.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlayxCore.bootCore();

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
  await PlayxLocalization.boot(config: config);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayxLocalizationBuilder(builder: (_, locale) {
      return MaterialApp(
        supportedLocales: PlayxLocalization.supportedLocales,
        localizationsDelegates: PlayxLocalization.localizationDelegates,
        locale: locale.locale,
        home: const MyHomePage(),
      );
    });
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    print('Current Locale: ${PlayxLocalization.currentLocale} context :${context.locale.toStringWithSeparator()}');
    return Scaffold(
        appBar: AppBar(
          title: Text(
            AppTrans.changeLanguageTitle.tr(context: context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${context.tr(AppTrans.changeLanguageTitle)} : بلاي',
                  style: TextStyle(
                      fontSize: 18,
                      color:
                      ('${context.tr(AppTrans.changeLanguageTitle)} : بلاي')
                          .isArabic
                          ? Colors.blueAccent
                          : Colors.black),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (ctx) => Center(
                              child: Card(
                                margin: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppTrans.changeLanguageTitle
                                          .tr(context: context),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    ...PlayxLocalization.supportedXLocales
                                        .map((e) => ListTile(
                                      onTap: () {
                                        PlayxLocalization.updateById(
                                            e.id,
                                            forceAppUpdate: false);
                                        Navigator.pop(ctx);
                                      },
                                      title: Text(e.name),
                                      trailing: PlayxLocalization
                                          .currentXLocale.id ==
                                          e.id
                                          ? const Icon(
                                        Icons.done,
                                        color: Colors.lightBlue,
                                      )
                                          : const SizedBox.shrink(),
                                    ))
                                        ,
                                  ],
                                ),
                              )));
                    },
                    child: Text(AppTrans.chooseLanguage.tr(context: context)))
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            PlayxLocalization.updateByIndex(
                PlayxLocalization.isCurrentLocaleArabic() ? 0 : 1,
                forceAppUpdate: false);
          },
          label: Text(
            'change_language_title'.tr(context: context),
          ),
          icon: const Icon(Icons.update),
        ));
  }
}
