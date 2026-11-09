import 'package:playx_core/playx_core.dart';

/// Abstraction over where Playx Localization persists the last selected locale.
///
/// Implement it to store the values anywhere (secure storage, Hive, a backend,
/// ...) and pass it through `PlayxLocaleConfig.storage`.
abstract interface class PlayxLocaleStorage {
  /// Reads the integer saved under [key], or `null` if there is none.
  Future<int?> getInt(String key);

  /// Saves [value] under [key].
  Future<void> setInt(String key, int value);

  /// Reads the string saved under [key], or `null` if there is none.
  Future<String?> getString(String key);

  /// Saves [value] under [key].
  Future<void> setString(String key, String value);

  /// Removes the value saved under [key].
  Future<void> remove(String key);
}

/// Default storage backed by `PlayxAsyncPrefs` (SharedPreferencesAsync).
class PlayxPrefsLocaleStorage implements PlayxLocaleStorage {
  const PlayxPrefsLocaleStorage();

  @override
  Future<int?> getInt(String key) async {
    await PlayxAsyncPrefs.create();
    return PlayxAsyncPrefs.maybeGetInt(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await PlayxAsyncPrefs.create();
    return PlayxAsyncPrefs.setInt(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    await PlayxAsyncPrefs.create();
    return PlayxAsyncPrefs.maybeGetString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await PlayxAsyncPrefs.create();
    return PlayxAsyncPrefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await PlayxAsyncPrefs.create();
    return PlayxAsyncPrefs.remove(key);
  }
}

/// In-memory storage. Nothing survives an app restart; useful for tests.
class PlayxMemoryLocaleStorage implements PlayxLocaleStorage {
  final Map<String, Object> _values;

  PlayxMemoryLocaleStorage([Map<String, Object>? initialValues])
      : _values = {...?initialValues};

  @override
  Future<int?> getInt(String key) async {
    final value = _values[key];
    return value is int ? value : null;
  }

  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;

  @override
  Future<String?> getString(String key) async {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
