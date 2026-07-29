// File: lib/services/shared_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static final SharedPreferencesService _instance = 
      SharedPreferencesService._internal();
  factory SharedPreferencesService() => _instance;
  SharedPreferencesService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool wasNotificationSent(String key) {
    return _prefs.getBool(key) ?? false;
  }

  void markNotificationSent(String key) {
    _prefs.setBool(key, true);
  }

  void clearNotificationHistory() {
    // Clear all notification flags older than 7 days
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('event_notification_')) {
        _prefs.remove(key);
      }
    }
  }
}