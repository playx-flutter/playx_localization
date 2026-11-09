import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart' hide TextDirection;
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/easy_localization/localization.dart';

import 'helpers.dart';

const en = XLocale(
    id: 'en', name: 'English', languageCode: 'en', fontFamily: 'Roboto');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');

final data = {
  'en': {
    'title': 'Title',
    'item': {'one': '{} item', 'other': '{} items'},
    'greet': 'Hi {name}',
  },
  'ar': {
    'title': 'عنوان',
    'item': {'one': '{} عنصر', 'other': '{} عناصر'},
    'greet': 'مرحبا {name}',
  },
};

Future<PlayxLocaleController> boot({XLocale start = en}) async {
  final c = PlayxLocaleController(
    config: PlayxLocaleConfig(
      supportedLocales: const [en, ar],
      startLocale: start,
      fallbackLocale: en,
      assetLoader: MemoryAssetLoader(data),
      storage: PlayxMemoryLocaleStorage(),
      logLocaleChanges: false,
    ),
  );
  await c.boot();
  return c;
}

Widget app(Widget Function(BuildContext) build) => Directionality(
      textDirection: TextDirection.ltr,
      child: PlayxLocalizationBuilder(
        builder: (context, xLocale) => Builder(builder: build),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('builder rebuilds when the locale changes', (tester) async {
    final c = await boot();
    await tester.pumpWidget(app((context) => Text(context.tr('title'))));
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsOneWidget);

    await tester.runAsync(() => c.updateTo(ar));
    await tester.pumpAndSettle();
    expect(find.text('عنوان'), findsOneWidget);
    expect(find.text('Title'), findsNothing);
  });

  testWidgets('builder rebuilds after translations are reloaded',
      (tester) async {
    final c = await boot();
    var builds = 0;
    await tester.pumpWidget(app((context) {
      builds++;
      return Text(context.tr('title'));
    }));
    await tester.pumpAndSettle();
    final before = builds;
    await tester.runAsync(c.reloadTranslations);
    await tester.pumpAndSettle();
    expect(builds, greaterThan(before));
  });

  testWidgets('context helpers', (tester) async {
    await boot(start: ar);
    late BuildContext ctx;
    await tester.pumpWidget(app((context) {
      ctx = context;
      return const SizedBox();
    }));
    await tester.pumpAndSettle();

    expect(ctx.currentXLocale, ar);
    expect(ctx.currentLocale, const Locale('ar'));
    expect(ctx.localeTag, 'ar');
    expect(ctx.currentLanguageCode, 'ar');
    expect(ctx.fontFamily, isNull);
    expect(ctx.isCurrentLocaleArabic, isTrue);
    expect(ctx.isCurrentLocaleEnglish, isFalse);
    expect(ctx.isCurrentLocaleRtl, isTrue);
    expect(ctx.isCurrentLocaleLtr, isFalse);
    expect(ctx.isDeviceLocaleSelected, isFalse);
  });

  testWidgets('font family comes from the XLocale', (tester) async {
    await boot();
    late BuildContext ctx;
    await tester.pumpWidget(app((context) {
      ctx = context;
      return const SizedBox();
    }));
    await tester.pumpAndSettle();
    expect(ctx.fontFamily, 'Roboto');
  });

  testWidgets('context.tr and context.plural', (tester) async {
    await boot();
    late BuildContext ctx;
    await tester.pumpWidget(app((context) {
      ctx = context;
      return const SizedBox();
    }));
    await tester.pumpAndSettle();

    expect(ctx.tr('title'), 'Title');
    expect(ctx.tr('greet', namedArgs: {'name': 'Sam'}), 'Hi Sam');
    expect(ctx.tr('title', translate: false), 'title');
    expect(ctx.tr('title', locale: const Locale('ar')), 'title');
    expect(ctx.plural('item', 1), '1 item');
    expect(ctx.plural('item', 4), '4 items');
    expect(ctx.plural('item', 4, translate: false), 'item');
    // String and Text extensions with a context.
    expect('title'.tr(context: ctx), 'Title');
    expect('item'.plural(2, context: ctx), '2 items');
    expect(const Text('title').tr(context: ctx).data, 'Title');
    expect(const Text('item').plural(1, context: ctx).data, '1 item');
    expect('title'.trExists(), isTrue);
    expect('nope'.trExists(), isFalse);
  });

  testWidgets('context.tr throws without a Localization', (tester) async {
    await boot();
    late BuildContext ctx;
    await tester.pumpWidget(Builder(builder: (context) {
      ctx = context;
      return const SizedBox();
    }));
    expect(() => ctx.tr('title'), throwsException);
    expect(() => ctx.plural('item', 1), throwsException);
    expect(() => ctx.currentXLocale, throwsException);
    expect(PlayxInheritedLocalization.maybeOf(ctx), isNull);
  });

  test('inherited widget notifies only when the locale changes', () {
    PlayxInheritedLocalization host(XLocale locale) =>
        PlayxInheritedLocalization(locale: locale, child: const SizedBox());
    expect(host(en).updateShouldNotify(host(en)), isFalse);
    expect(host(ar).updateShouldNotify(host(en)), isTrue);
  });

  testWidgets('Localization.of finds the delegate in the tree',
      (tester) async {
    await boot();
    late BuildContext ctx;
    await tester.pumpWidget(app((context) {
      ctx = context;
      return const SizedBox();
    }));
    await tester.pumpAndSettle();
    expect(Localization.of(ctx), isNotNull);
    expect(Localization.of(ctx)!.tr('title'), 'Title');
  });

  group('delegate', () {
    test('supports configured locales only and never reloads', () async {
      final c = await boot();
      final d = c.delegate;
      expect(d.isSupported(const Locale('en')), isTrue);
      expect(d.isSupported(const Locale('fr')), isFalse);
      expect(d.shouldReload(d), isFalse);
    });

    test('loads translations itself when none are loaded', () async {
      final c = PlayxLocaleController(
        config: PlayxLocaleConfig(
          supportedLocales: const [en, ar],
          assetLoader: MemoryAssetLoader(data),
          storage: PlayxMemoryLocaleStorage(),
          logLocaleChanges: false,
        ),
      );
      final d = PlayxLocalizationDelegate(
          localizationController: c, supportedLocales: const [en, ar]);
      expect(c.translations, isNull);

      final localization = await d.load(const Locale('ar'));
      expect(c.translations, isNotNull);
      expect(localization.tr('title'), 'عنوان');
    });

    test('throws for a locale that is not supported', () async {
      final c = PlayxLocaleController(
        config: PlayxLocaleConfig(
          supportedLocales: const [en],
          assetLoader: MemoryAssetLoader(data),
          storage: PlayxMemoryLocaleStorage(),
          logLocaleChanges: false,
        ),
      );
      final d = PlayxLocalizationDelegate(
          localizationController: c, supportedLocales: const [en]);
      expect(() => d.load(const Locale('de')), throwsUnsupportedError);
    });
  });
}
