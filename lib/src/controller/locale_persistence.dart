import 'package:playx_core/playx_core.dart';

import '../model/x_locale.dart';
import '../storage/locale_storage.dart';

/// What was saved by a previous run.
///
/// - [id]: id of the selected [XLocale], or [LocalePersistence.deviceMarker]
///   when the app follows the device locale.
/// - [index]: legacy position in `supportedLocales` (`-1` = follow device).
///   Written by versions before 0.5.0, which only stored the index.
typedef SavedLocale = ({String? id, int? index});

/// Reads and writes the selected locale through a [PlayxLocaleStorage].
///
/// The locale is saved by **id**, so reordering or inserting locales in
/// `supportedLocales` doesn't restore the wrong language. The index is still
/// written next to it so older versions of the package keep working after a
/// downgrade, and it is read when no id was saved yet (migration).
///
/// All operations run one after another in call order, so when locales are
/// switched quickly the last requested locale is always the last one written.
class LocalePersistence {
  LocalePersistence(this.storage);

  /// Legacy and still written key: position in `supportedLocales`.
  static const indexKey = 'playx.locale.last_known_index';

  /// Id of the selected locale.
  static const idKey = 'playx.locale.last_known_id';

  /// Stored under [idKey] when the app follows the device locale.
  static const deviceMarker = '__device__';

  final PlayxLocaleStorage storage;

  Future<void> _queue = Future<void>.value();
  int _pending = 0;

  /// Runs [operation] after every previously queued one finished. A failure
  /// is reported to the caller but doesn't block the operations after it.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final Future<T> result = _pending == 0
        ? Future<T>.sync(operation)
        : _queue.then((_) => operation());
    _pending++;
    _queue = result.then<void>((_) => _pending--, onError: (_) => _pending--);
    return result;
  }

  /// The saved locale.
  ///
  /// If [migrateLegacyPrefs] is true and nothing was saved yet, the index saved
  /// by old versions in `PlayxPrefs` (SharedPreferences) is copied to the
  /// storage.
  Future<SavedLocale> load({bool migrateLegacyPrefs = false}) =>
      _enqueue(() async {
        final id = await storage.getString(idKey);
        var index = await storage.getInt(indexKey);
        if (migrateLegacyPrefs && id == null && index == null) {
          await PlayxPrefs.create();
          final legacy = PlayxPrefs.maybeGetInt(indexKey);
          if (legacy != null) {
            await storage.setInt(indexKey, legacy);
            index = legacy;
          }
        }
        return (id: id, index: index);
      });

  /// Saves [locale], located at [index] in `supportedLocales`.
  Future<void> saveLocale(XLocale locale, int index) => _enqueue(() async {
    await storage.setString(idKey, locale.id);
    await storage.setInt(indexKey, index);
  });

  /// Saves that the app follows the device locale.
  Future<void> saveDeviceLocale() => _enqueue(() async {
    await storage.setString(idKey, deviceMarker);
    await storage.setInt(indexKey, -1);
  });

  /// Removes everything saved.
  Future<void> clear() => _enqueue(() async {
    await storage.remove(idKey);
    await storage.remove(indexKey);
  });
}
