import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('date helpers use the full locale, not only the language', () async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('de_AT');

    const de = XLocale(id: 'de', name: 'Deutsch', languageCode: 'de');
    const deAT = XLocale(
      id: 'de_at',
      name: 'Österreich',
      languageCode: 'de',
      countryCode: 'AT',
    );
    final date = DateTime(2024, 1, 15, 9, 30);

    Future<void> bootWith(XLocale locale) async {
      final c = PlayxLocaleController(
        config: PlayxLocaleConfig(
          supportedLocales: [de, deAT],
          startLocale: locale,
          assetLoader: MemoryAssetLoader({
            'de': {'k': 'v'},
            'de-AT': {'k': 'v'},
          }),
          storage: PlayxMemoryLocaleStorage(),
          logLocaleChanges: false,
        ),
      );
      await c.boot();
    }

    await bootWith(de);
    expect(date.toFormattedDate(format: 'MMMM'), 'Januar');

    await bootWith(deAT);
    expect(date.toFormattedDate(format: 'MMMM'), 'Jänner');
    expect(date.toFormattedTime(format: 'MMMM'), 'Jänner');

    // An explicit locale still wins.
    expect(date.toFormattedDate(format: 'MMMM', locale: 'de'), 'Januar');
  });
}
