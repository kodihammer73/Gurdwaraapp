// lib/services/notification_service.dart

import 'dart:io' show Platform;
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart' as app;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _siteBaseUrl = 'https://www.gurdwarasahibmelaka.com';
  static const String _eventsUrl = '$_siteBaseUrl/events.txt';
  static const String _registerDeviceUrl = '$_siteBaseUrl/api/register_device.php';
  static const String _diagnosticsUrl = '$_siteBaseUrl/api/ios_diag.php';
  static const String _workManagerTask = 'event_notification_task';

  /// Callback invoked when a notification is tapped while the app is open.
  /// The app registers this so it can navigate to the relevant screen.
  static void Function(String screen)? onNotificationTap;

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio();
  late SharedPreferences _prefs;

  /// Live FCM/APNs registration status, shown on-screen at launch so the
  /// committee can see exactly what step registration reached (or why it
  /// failed) without needing a debug console.
  static final ValueNotifier<String> registrationStatus =
      ValueNotifier<String>('Notifications: registering…');

  static void _setStatus(String s) {
    registrationStatus.value = s;
    print('🔔 status: $s');
  }


  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    try {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
      );
    } catch (e) {
      print('⚠️ localNotifications.initialize threw: $e');
    }

    // Diagnostics are sent FIRST (before any Firebase calls that could throw)
    // so we always capture the on-device state even if permission/token calls fail.
    await _reportDiagnostics();

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('⚠️ requestPermission threw: $e');
    }

    // Fetch the FCM/APNs token. On iOS, the APNs token often isn't ready
    // immediately at cold launch, so retry for a while before giving up.
    // This closes the gap where a device never registers because the token
    // was null on the first attempt and the app was closed before the
    // asynchronous refresh fired.
    final String? token = await _getTokenWithRetry(
      maxAttempts: 8,
      delay: const Duration(milliseconds: 1500),
    );
    if (token != null) {
      print('FCM Token: $token');
      _prefs.setString('fcm_token', token);
      _setStatus('Token received — sending to server…');
      await _registerDeviceToken(token);
    } else {
      print('⚠️ FCM/APNs token unavailable after retries (iOS may still deliver later via refresh)');
      if (!_lastApnsTokenPresent) {
        _setStatus('⚠️ No APNs token. App likely signed WITHOUT push entitlement '
            '(regenerate the distribution profile with Push enabled), or the APNs '
            'key is missing in Firebase. Detail: ${_short(_lastTokenError)}');
      } else {
        _setStatus('⚠️ APNs OK but no FCM token. Check Firebase setup / network. '
            'Detail: ${_short(_lastTokenError)}');
      }
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('FCM Token refreshed: $token');
      _prefs.setString('fcm_token', token);
      _registerDeviceToken(token);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      await Workmanager().registerPeriodicTask(
        'event_notification_check',
        _workManagerTask,
        frequency: const Duration(hours: 12),
        initialDelay: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      print('⚠️ Workmanager init failed: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    final notificationService = NotificationService();
    await notificationService._showLocalNotification(message);
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        if (task == _workManagerTask) {
          final notificationService = NotificationService();
          await notificationService.checkAndSendEventNotifications();
        }
        return true;
      } catch (e) {
        print('WorkManager task failed: $e');
        return false;
      }
    });
  }

  Future<void> checkAndSendEventNotifications() async {
    try {
      final events = await _fetchAllEvents();
      final upcomingEvents = _getEventsStartingIn12Hours(events);
      
      if (upcomingEvents.isNotEmpty) {
        final notificationKey = _getNotificationKey(upcomingEvents);
        if (!_wasNotificationSent(notificationKey)) {
          await _sendCombinedNotification(upcomingEvents);
          _markNotificationSent(notificationKey);
        }
      }
    } catch (e) {
      print('Error checking events: $e');
    }
  }

  Future<List<app.HomepageEvent>> _fetchAllEvents() async {
    try {
      final response = await _dio.get<String>(_eventsUrl);
      final text = response.data ?? '';
      final events = app.parseHomepageEvents(text);
      
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  List<app.HomepageEvent> _getEventsStartingIn12Hours(List<app.HomepageEvent> events) {
    final now = DateTime.now();
    
    return events.where((event) {
      final eventDateTime = app.dateOnly(event.date);
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      if (eventDateTime.isAtSameMomentAs(today) || eventDateTime.isAtSameMomentAs(tomorrow)) {
        if (eventDateTime.isAtSameMomentAs(today)) {
          return now.hour < 12;
        }
        return now.hour >= 20;
      }
      return false;
    }).toList();
  }

  String _getNotificationKey(List<app.HomepageEvent> events) {
    final eventIds = events.map((e) => '${e.title}_${e.date.toIso8601String()}').join('_');
    final dateKey = DateTime.now().toIso8601String().substring(0, 10);
    return 'event_notification_${dateKey}_${eventIds.hashCode}';
  }

  bool _wasNotificationSent(String key) {
    return _prefs.getBool(key) ?? false;
  }

  void _markNotificationSent(String key) {
    _prefs.setBool(key, true);
    _cleanupOldNotifications();
  }

  void _cleanupOldNotifications() {
    final keys = _prefs.getKeys();
    final notificationKeys = keys
        .where((k) => k.startsWith('event_notification_'))
        .toList()
      ..sort();
    
    if (notificationKeys.length > 100) {
      for (int i = 0; i < notificationKeys.length - 100; i++) {
        _prefs.remove(notificationKeys[i]);
      }
    }
  }

  Future<void> _sendCombinedNotification(List<app.HomepageEvent> events) async {
    final String title = events.length == 1 
        ? '⏰ Event Tomorrow: ${events[0].title}'
        : '⏰ ${events.length} Events Coming Up!';
    
    final String body = events.length == 1
        ? '${events[0].title} is scheduled for ${DateFormat('d MMM, h:mm a').format(events[0].date)}'
        : events.map((e) => '• ${e.title} (${DateFormat('d MMM, h:mm a').format(e.date)})').join('\n');

    final androidDetails = AndroidNotificationDetails(
      'event_channel',
      'Event Notifications',
      channelDescription: 'Notifications for upcoming events',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFF2E7D32),
      styleInformation: const BigTextStyleInformation(''),
    );

    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'event_category',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ⭐ FIX: New show() method signature
    await _localNotifications.show(
      events.hashCode.abs(),
      title,
      body,
      details,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'event_channel',
      'Event Notifications',
      channelDescription: 'Notifications for upcoming events',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ⭐ FIX: New show() method signature
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      message.notification?.title ?? 'Event Reminder',
      message.notification?.body ?? 'You have an upcoming event!',
      details,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Determine the target screen from the notification payload.
    // Default to the Calendar tab for event notifications.
    final data = message.data;
    final screen = (data['screen'] as String?) ?? 'calendar';
    onNotificationTap?.call(screen);
  }


  /// Register this device's FCM token with the backend server.
  Future<void> _registerDeviceToken(String token) async {
    final String platform = _getPlatform();
    final String appVersion = await _getAppVersion();
    try {
      final response = await _dio.post(
        _registerDeviceUrl,
        data: {
          'token': token,
          'platform': platform,
          'app_version': appVersion,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      print('✅ Device token registered with backend'
          ' (platform=$platform, appVersion=$appVersion)');
      print('   HTTP ${response.statusCode}: ${response.data}');
      _setStatus('✅ Notifications ready (HTTP ${response.statusCode})');
    } catch (e) {
      // Expose the real error so iOS registration failures are visible
      // in the run log instead of being silently swallowed.
      print('⚠️ Failed to register device token '
          '(platform=$platform, appVersion=$appVersion): $e');
      String reason = e.toString();
      if (reason.length > 140) reason = '${reason.substring(0, 140)}…';
      _setStatus('❌ Register failed: $reason');
    }
  }

  /// Gathers the on-device Firebase Messaging state and posts it to the backend
  /// so the admin panel can show exactly why a device could not obtain a token.
  /// This is especially important on iOS, where a missing APNs entitlement or
  /// unconfigured Firebase APNs key silently prevents token acquisition.
  Future<void> _reportDiagnostics() async {
    try {
      bool supported = false;
      String? apnsToken;
      String? fcmToken;
      String authStatus = 'notDetermined';

      try {
        supported = await FirebaseMessaging.instance.isSupported();
      } catch (e) {
        print('⚠️ diag isSupported: $e');
      }
      try {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      } catch (e) {
        print('⚠️ diag getAPNSToken: $e');
      }
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print('⚠️ diag getToken: $e');
      }
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        authStatus = settings.authorizationStatus.name;
      } catch (e) {
        print('⚠️ diag getNotificationSettings: $e');
      }

      final payload = <String, dynamic>{
        'platform': _getPlatform(),
        'app_version': await _getAppVersion(),
        'is_supported': supported,
        'apns_token': _maskToken(apnsToken),
        'fcm_token': _maskToken(fcmToken),
        'auth_status': authStatus,
        'apns_token_present': apnsToken != null && apnsToken.isNotEmpty ? 'true' : 'false',
        'last_token_error': _lastTokenError,
      };

      final resp = await _dio.post(
        _diagnosticsUrl,
        data: payload,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      print('📡 Firebase Messaging diagnostics reported: HTTP ${resp.statusCode} ${resp.data}');
    } catch (e) {
      print('⚠️ Could not report Firebase Messaging diagnostics: $e');
    }
  }

  /// Returns the first 16 chars of a token (or ''), to avoid logging full
  /// credentials while still confirming a token exists.
  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return '';
    return token.length <= 16 ? token : token.substring(0, 16);
  }

  /// Best-effort platform label reported to the backend so Admin can tell
  /// iOS from Android. Falls back to a generic value if detection is unsure.
  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Reads the installed app version (from pubspec.yaml at build time) so the
  /// backend stores the real version instead of a hardcoded "1.0.0".
  Future<String> _getAppVersion() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      if (pkg.version.isNotEmpty) {
        return pkg.version;
      }
    } catch (e) {
      print('⚠️ Could not read app version, defaulting to 1.0.0: $e');
    }
    return '1.0.0';
  }

  /// Attempts to fetch the FCM/APNs token up to [maxAttempts] times, waiting
  /// [delay] between attempts. iOS often needs a moment before the APNs token
  /// is available, so retrying here avoids permanently missing registration.
  /// Never throws: a failed `getToken()` is treated as "not ready yet" and
  /// retried, so an iOS plugin exception cannot abort the startup flow before
  /// diagnostics/registration run.
  Future<String?> _getTokenWithRetry({
    required int maxAttempts,
    required Duration delay,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      if (i > 0) {
        await Future.delayed(delay);
      }
      try {
        // Check APNs reachability first — FCM cannot mint a token without it.
        final String? apns = await FirebaseMessaging.instance.getAPNSToken();
        _lastApnsTokenPresent = apns != null && apns.isNotEmpty;
        final String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          print('FCM/APNs token obtained on attempt ${i + 1}');
          return token;
        }
        _lastTokenError = 'getToken() returned null (attempt ${i + 1})';
      } catch (e) {
        print('⚠️ getToken() threw on attempt ${i + 1}: $e');
        _lastTokenError = e.toString();
      }
    }
    return null;
  }

  /// Last error observed while fetching the FCM token (for on-screen banner).
  String _lastTokenError = '';

  /// Whether an APNs token was ever observed during the last retry loop.
  bool _lastApnsTokenPresent = false;

  /// Truncates a diagnostic string for the on-screen banner.
  String _short(String s, [int max = 110]) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  Future<void> manualCheckAndNotify() async {
    await checkAndSendEventNotifications();
  }

  Future<void> testNotification() async {
    final testEvents = [
      app.HomepageEvent(
        title: 'Test Event',
        date: DateTime.now().add(const Duration(hours: 6)),
        details: 'This is a test event notification',
        imagePath: '',
      ),
    ];
    await _sendCombinedNotification(testEvents);
  }
}