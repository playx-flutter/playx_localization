import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playx_localization/playx_localization.dart';
import 'package:playx_localization/src/controller/controller.dart';
import 'package:playx_localization/src/controller/locale_persistence.dart';
import 'package:playx_localization/src/controller/locale_resolver.dart';

import 'helpers.dart';

const en = XLocale(id: 'en', name: 'English', languageCode: 'en');
const ar = XLocale(id: 'ar', name: 'Arabic', languageCode: 'ar');
const fr = XLocale(id: 'fr', name: 'French', languageCode: 'fr');
const enGB = XLocale(
  id: 'en_gb',
  name: 'English UK',
  languageCode: 'en',
  countryCode: 'GB',
);

PlayxLocaleConfig cfg(
  List<XLocale> locales, {
  XLocale? start,
  XLocale? fallback,
  PlayxLocaleStorage? storage,
  bool save = true,
}) => PlayxLocaleConfig(
  supportedLocales: locales,
  startLocale: start,
  fallbackLocale: fallback,
  assetLoader: MemoryAssetLoader({
    for (final l in locales) l.locale.toLanguageTag(): {'k': l.name},
  }),
  storage: storage ?? PlayxMemoryLocaleStorage(),
  saveLocale: save,
  logLocaleChanges: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleResolver', () {
    final config = cfg([en, ar, fr], start: ar);

    test('saved id wins over start locale', () {
      final r = LocaleResolver.resolveBoot(
        config,
        saved: (id: 'fr', index: 1),
        deviceLocale: const Locale('en'),
      );
      expect(r.locale, fr);
      expect(r.fromLegacyIndex, isFalse);
      expect(r.isDeviceSelected, isFalse);
    });

    test('reordered list: id is used, not the stale index', () {
      final reordered = cfg([fr, en, ar]);
      final r = LocaleResolver.resolveBoot(
        reordered,
        saved: (id: 'ar', index: 1),
        deviceLocale: null,
      );
      expect(r.locale, ar);
    });

    test('removed id falls back to the default, ignoring the index', () {
      final r = LocaleResolver.resolveBoot(
        cfg([en, ar], start: en),
        saved: (id: 'fr', index: 1),
        deviceLocale: null,
      );
      expect(r.locale, en);
    });

    test('legacy index is used when there is no id, and flagged', () {
      final r = LocaleResolver.resolveBoot(
        config,
        saved: (id: null, index: 2),
        deviceLocale: null,
      );
      expect(r.locale, fr);
      expect(r.fromLegacyIndex, isTrue);
    });

    test('out of range legacy index is ignored', () {
      final r = LocaleResolver.resolveBoot(
        config,
        saved: (id: null, index: 9),
        deviceLocale: null,
      );
      expect(r.locale, ar);
      expect(r.fromLegacyIndex, isFalse);
    });

    test('device marker and legacy -1 follow the device, ignoring start', () {
      for (final saved in [
        (id: LocalePersistence.deviceMarker, index: -1),
        (id: null, index: -1),
      ]) {
        final r = LocaleResolver.resolveBoot(
          config,
          saved: saved,
          deviceLocale: const Locale('fr', 'FR'),
        );
        expect(r.locale, fr);
        expect(r.isDeviceSelected, isTrue);
      }
    });

    test('nothing saved: start, then device, then fallback', () {
      expect(
        LocaleResolver.resolveBoot(
          config,
          saved: (id: null, index: null),
          deviceLocale: null,
        ).locale,
        ar,
      );
      final noStart = cfg([en, ar, fr]);
      expect(
        LocaleResolver.resolveBoot(
          noStart,
          saved: (id: null, index: null),
          deviceLocale: const Locale('fr'),
        ).locale,
        fr,
      );
      expect(
        LocaleResolver.resolveBoot(
          noStart,
          saved: (id: null, index: null),
          deviceLocale: const Locale('de'),
        ).locale,
        en,
      );
    });

    test('device region falls back to language match', () {
      expect(
        LocaleResolver.matchDevice(cfg([en, ar]), const Locale('ar', 'EG')),
        ar,
      );
      expect(
        LocaleResolver.matchDevice(cfg([enGB, ar]), const Locale('en', 'US')),
        enGB,
      );
    });

    test('fallbackLocale prefers config, then English, then first', () {
      expect(LocaleResolver.fallbackLocale(cfg([ar, fr], fallback: fr)), fr);
      expect(LocaleResolver.fallbackLocale(cfg([ar, en])), en);
      expect(LocaleResolver.fallbackLocale(cfg([ar, fr])), ar);
    });
  });

  group('LocalePersistence', () {
    test('saves id and index; device sync writes marker and -1', () async {
      final storage = PlayxMemoryLocaleStorage();
      final p = LocalePersistence(storage);
      await p.saveLocale(ar, 1);
      expect(await p.load(), (id: 'ar', index: 1));
      await p.saveDeviceLocale();
      expect(await p.load(), (id: LocalePersistence.deviceMarker, index: -1));
      await p.clear();
      expect(await p.load(), (id: null, index: null));
    });

    test('reads a legacy index-only value', () async {
      final p = LocalePersistence(
        PlayxMemoryLocaleStorage({LocalePersistence.indexKey: 1}),
      );
      expect(await p.load(), (id: null, index: 1));
    });

    test('operations run in call order', () async {
      final slow = _SlowStorage();
      final p = LocalePersistence(slow);
      final a = p.saveLocale(en, 0);
      final b = p.saveLocale(ar, 1);
      await Future.wait([a, b]);
      expect((await p.load()).id, 'ar');
    });

    test('a failing operation does not block the next ones', () async {
      final p = LocalePersistence(_FailingOnceStorage());
      await expectLater(p.saveLocale(en, 0), throwsStateError);
      await p.saveLocale(ar, 1);
      expect((await p.load()).id, 'ar');
    });
  });

  group('controller persistence and migration', () {
    test('restores by id after the supported list is reordered', () async {
      final storage = PlayxMemoryLocaleStorage();
      final first = PlayxLocaleController(
        config: cfg([en, ar, fr], storage: storage),
      );
      await first.boot();
      await first.updateTo(ar);

      final second = PlayxLocaleController(
        config: cfg([fr, ar, en], storage: storage),
      );
      await second.boot();
      expect(second.value, ar);
    });

    test('migrates a legacy index to an id on boot', () async {
      final storage = PlayxMemoryLocaleStorage({LocalePersistence.indexKey: 2});
      final c = PlayxLocaleController(
        config: cfg([en, ar, fr], storage: storage),
      );
      await c.boot();
      expect(c.value, fr);
      expect(await storage.getString(LocalePersistence.idKey), 'fr');
      expect(await storage.getInt(LocalePersistence.indexKey), 2);
    });

    test('legacy -1 keeps following the device after migration', () async {
      final storage = PlayxMemoryLocaleStorage({
        LocalePersistence.indexKey: -1,
      });
      final c = PlayxLocaleController(config: cfg([en, ar], storage: storage));
      await c.boot();
      expect(c.isDeviceLocaleSelected, isTrue);
    });

    test(
      'a locale removed in an update falls back instead of a wrong one',
      () async {
        final storage = PlayxMemoryLocaleStorage();
        final old = PlayxLocaleController(
          config: cfg([en, ar, fr], storage: storage),
        );
        await old.boot();
        await old.updateTo(fr);

        final updated = PlayxLocaleController(
          config: cfg([en, ar], start: en, storage: storage),
        );
        await updated.boot();
        expect(updated.value, en);
      },
    );

    test('saveLocale: false writes nothing', () async {
      final storage = PlayxMemoryLocaleStorage();
      final c = PlayxLocaleController(
        config: cfg([en, ar], storage: storage, save: false),
      );
      await c.boot();
      await c.updateTo(ar);
      expect(await storage.getString(LocalePersistence.idKey), isNull);
    });

    test(
      'resetLocale forgets the saved locale and does not save the result',
      () async {
        final storage = PlayxMemoryLocaleStorage();
        final c = PlayxLocaleController(
          config: cfg([en, ar], start: en, storage: storage),
        );
        await c.boot();
        await c.updateTo(ar);
        await c.resetLocale();
        expect(c.value, en);
        expect(await storage.getString(LocalePersistence.idKey), isNull);
        expect(await storage.getInt(LocalePersistence.indexKey), isNull);
      },
    );

    test('deleteSavedLocale clears id and index', () async {
      final storage = PlayxMemoryLocaleStorage();
      final c = PlayxLocaleController(config: cfg([en, ar], storage: storage));
      await c.boot();
      await c.updateTo(ar);
      await c.deleteSavedLocale();
      expect(await storage.getString(LocalePersistence.idKey), isNull);
    });
  });
}

class _SlowStorage extends PlayxMemoryLocaleStorage {
  int _calls = 0;

  @override
  Future<void> setString(String key, String value) async {
    // The first write is slower, so out-of-order execution would let it win.
    final delay = _calls++ == 0 ? 30 : 0;
    await Future<void>.delayed(Duration(milliseconds: delay));
    return super.setString(key, value);
  }
}

class _FailingOnceStorage extends PlayxMemoryLocaleStorage {
  bool _failed = false;

  @override
  Future<void> setString(String key, String value) async {
    if (!_failed) {
      _failed = true;
      throw StateError('disk full');
    }
    return super.setString(key, value);
  }
}
