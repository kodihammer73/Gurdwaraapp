// lib/services/version_check_service.dart
//
// Force-update / version check service.
// Fetches the app version config from the website and compares it against
// the installed app version to determine whether an update is required.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Result of a version check.
class VersionCheckResult {
  const VersionCheckResult({
    required this.updateRequired,
    required this.forceUpdate,
    required this.latestVersion,
    required this.minimumVersion,
    required this.playStoreUrl,
    required this.updateMessage,
  });

  /// Whether the installed version is below the minimum required version.
  final bool updateRequired;

  /// Whether the update is mandatory (non-dismissible dialog).
  final bool forceUpdate;

  /// The latest available version string (e.g. "1.0.2").
  final String latestVersion;

  /// The minimum version that is still allowed to run.
  final String minimumVersion;

  /// URL to the app store listing for updating.
  final String playStoreUrl;

  /// Message shown to the user in the update dialog.
  final String updateMessage;

  /// A result indicating no update is required (used as a safe fallback).
  static const VersionCheckResult none = VersionCheckResult(
    updateRequired: false,
    forceUpdate: false,
    latestVersion: '',
    minimumVersion: '',
    playStoreUrl: '',
    updateMessage: '',
  );
}

class VersionCheckService {
  VersionCheckService({Dio? dio}) : _dio = dio ?? Dio();

  static const String _siteBaseUrl = 'https://www.gurdwarasahibmelaka.com';
  static const String _versionConfigUrl = '$_siteBaseUrl/app_version.json';

  final Dio _dio;

  /// Fetches the remote version config and compares it against the installed
  /// app version. Returns a [VersionCheckResult].
  ///
  /// On any network/parse error, returns [VersionCheckResult.none] so the app
  /// continues to work normally (fail-open behaviour).
  Future<VersionCheckResult> checkForUpdate() async {
    try {
      final installedVersion = await _getInstalledVersion();
      final config = await _fetchVersionConfig();

      final minimumVersion = config['minimum_version'] as String? ?? '';
      final latestVersion = config['latest_version'] as String? ?? '';
      final playStoreUrl = config['play_store_url'] as String? ?? '';
      final forceUpdate = config['force_update'] as bool? ?? false;
      final updateMessage =
          config['update_message'] as String? ??
          'A new version of the Gurdwara Sahib Melaka app is available. '
              'Please update to continue using the app.';

      if (minimumVersion.isEmpty) {
        return VersionCheckResult.none;
      }

      final updateRequired =
          _compareVersions(installedVersion, minimumVersion) < 0;

      return VersionCheckResult(
        updateRequired: updateRequired,
        forceUpdate: forceUpdate,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        playStoreUrl: playStoreUrl,
        updateMessage: updateMessage,
      );
    } catch (e) {
      print('⚠️ Version check failed (continuing normally): $e');
      return VersionCheckResult.none;
    }
  }

  /// Reads the installed app version using package_info_plus.
  Future<String> _getInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      print('⚠️ Could not read package info: $e');
      return '0.0.0';
    }
  }

  /// Fetches and decodes the remote version config JSON.
  Future<Map<String, dynamic>> _fetchVersionConfig() async {
    final response = await _dio.get<String>(
      _versionConfigUrl,
      options: Options(
        responseType: ResponseType.plain,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final raw = (response.data ?? '').trim();
    if (raw.isEmpty) {
      throw Exception('Empty version config response.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected version config format.');
    }
    return decoded;
  }

  /// Compares two semantic version strings (e.g. "1.2.3").
  ///
  /// Returns a negative number if [a] < [b], zero if equal, positive if [a] > [b].
  int _compareVersions(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);

    for (var i = 0; i < 3; i++) {
      if (aParts[i] != bParts[i]) {
        return aParts[i].compareTo(bParts[i]);
      }
    }
    return 0;
  }

  /// Parses a version string into [major, minor, patch] integers.
  /// Non-numeric segments are treated as 0.
  List<int> _parseVersion(String version) {
    final cleaned = version.trim().split('+').first; // strip build number
    final parts = cleaned.split('.');
    final result = <int>[];
    for (var i = 0; i < 3; i++) {
      final part = i < parts.length ? parts[i] : '0';
      result.add(int.tryParse(part.trim()) ?? 0);
    }
    return result;
  }
}
