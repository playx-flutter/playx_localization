class Translations {
  final Map<String, dynamic>? _translations;
  final Map<String?, dynamic> _nestedKeysCache;

  Translations(this._translations) : _nestedKeysCache = {};

  /// Returns the text for [key], or `null` if it is missing or is not a text
  /// (for example a group of nested keys).
  String? get(String key) {
    final translations = _translations;
    if (translations == null) return null;

    // A literal key wins, even if it contains dots.
    if (translations.containsKey(key)) return _asText(translations[key]);

    if (key.contains('.')) return getNested(key);
    return null;
  }

  String? getNested(String key) {
    if (isNestedCached(key)) return _nestedKeysCache[key];

    Object? value = _translations;
    for (final part in key.split('.')) {
      if (value is! Map) return null;
      value = value[part];
    }

    final text = _asText(value);

    /// Only found values are cached.
    if (text != null) cacheNestedKey(key, text);
    return text;
  }

  static String? _asText(Object? value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  bool isNestedCached(String key) => _nestedKeysCache.containsKey(key);

  void cacheNestedKey(String key, String value) {
    if (!isNestedKey(key)) {
      throw Exception('Cannot cache a key that is not nested.');
    }

    _nestedKeysCache[key] = value;
  }

  bool isNestedKey(String key) =>
      !(_translations?.containsKey(key) ?? false) && key.contains('.');

  @override
  String toString() {
    return _translations.toString();
  }
}
