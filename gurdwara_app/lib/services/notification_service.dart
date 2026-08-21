// lib/services/notification_service.dart

import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../main.dart' as app;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _siteBaseUrl = 'https://www.gurdwarasahibmelaka.com';
  static const String _eventsUrl = '$_siteBaseUrl/events.txt';
  static const String _registerDeviceUrl = '$_siteBaseUrl/api/register_device.php';
  static const String _workManagerTask = 'event_notification_task';

  /// Callback invoked when a notification is tapped while the app is open.
  /// The app registers this so it can navigate to the relevant screen.
  static void Function(String screen)? onNotificationTap;

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio();
  late SharedPreferences _prefs;


  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // ⭐ FIX: Initialize without settings (new API)
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

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        print('FCM Token: $token');
        _prefs.setString('fcm_token', token);
        _registerDeviceToken(token);
      }
    });

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


  /// Register this device's FCM token with the backend server
  Future<void> _registerDeviceToken(String token) async {
    try {
      await _dio.post(
        _registerDeviceUrl,
        data: {
          'token': token,
          'platform': 'android',
          'app_version': '1.0.0',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      print('✅ Device token registered with backend');
    } catch (e) {
      print('⚠️ Failed to register device token (server may not be set up yet): $e');
    }
  }

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