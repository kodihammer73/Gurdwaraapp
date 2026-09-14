// lib/services/app_settings_service.dart
//
// Fetches remote app-wide settings that the admin can toggle server-side
// WITHOUT rebuilding/releasing the app. Currently exposes `bookingsEnabled`,
// which controls whether the Booking & Tracking feature is shown in the app.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService({Dio? dio}) : _dio = dio ?? Dio();

  static const String _siteBaseUrl = 'https://www.gurdwarasahibmelaka.com';
  static const String _settingsUrl = '$_siteBaseUrl/api/app_settings.php';
  static const String _cacheKey = 'bookings_enabled';

  final Dio _dio;

  /// Whether the Booking & Tracking feature should be visible in the app.
  ///
  /// Fail-open: if the endpoint isn't deployed yet or the network fails, we
  /// fall back to the cached value (or `true`) so the feature is never hidden
  /// by an outage. The last known value is cached so launches work offline and
  /// the UI doesn't flash while the request completes.
  Future<bool> fetchBookingsEnabled() async {
    final cached = await _readCached();

    try {
      final response = await _dio.get<String>(
        _settingsUrl,
        options: Options(
          responseType: ResponseType.plain,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final raw = (response.data ?? '').trim();
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final enabled = decoded['bookings_enabled'] as bool? ?? true;
          await _writeCached(enabled);
          return enabled;
        }
      }
    } catch (_) {
      // Non-fatal: fall back to the cached/default value (Bookings stays visible).
    }

    return cached;
  }

  Future<bool> _readCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cacheKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _writeCached(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, enabled);
    } catch (_) {
      // Best-effort caching only.
    }
  }
}