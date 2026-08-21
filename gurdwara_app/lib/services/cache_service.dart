// lib/services/cache_service.dart
//
// Lightweight caching service using SharedPreferences for offline support.
// Caches API responses (events, gallery, about) so the app works without
// an internet connection and loads instantly on repeat visits.

import 'package:shared_preferences/shared_preferences.dart';

/// A simple caching service that stores API response strings locally.
class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  static const String _prefix = 'cache_';

  /// Saves a raw response body for the given key.
  Future<void> put(String key, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', body);
    } catch (_) {
      // Caching is best-effort; never fail the app because of it.
    }
  }

  /// Retrieves a cached response body, or null if not found/expired.
  Future<String?> get(String key, {Duration? maxAge}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final body = prefs.getString('$_prefix$key');
      if (body == null) return null;

      if (maxAge != null) {
        final savedAt = prefs.getInt('$_prefix${key}_time');
        if (savedAt == null) return null;
        final age = DateTime.now().millisecondsSinceEpoch - savedAt;
        if (age > maxAge.inMilliseconds) return null;
      }

      return body;
    } catch (_) {
      return null;
    }
  }

  /// Saves a response and records its timestamp.
  Future<void> putWithTimestamp(String key, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', body);
      await prefs.setInt(
        '$_prefix${key}_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Best-effort.
    }
  }

  /// Removes a cached entry.
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
      await prefs.remove('$_prefix${key}_time');
    } catch (_) {
      // Best-effort.
    }
  }

  /// Clears all cached entries.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Best-effort.
    }
  }
}