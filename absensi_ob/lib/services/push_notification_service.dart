import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../core/app_constants.dart';
import 'token_storage.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.ensureInitialized();
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _firebaseAvailable = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _firebaseAvailable = true;
    } catch (e) {
      debugPrint('Firebase belum dikonfigurasi: $e');
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings: initSettings);

    const androidChannel = AndroidNotificationChannel(
      'admin_messages',
      'Pesan Admin',
      description: 'Notifikasi pesan baru dari admin',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _requestPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      syncTokenToServer(token: token);
    });

    _initialized = true;
  }

  static Future<void> syncTokenToServer({String? token}) async {
    await ensureInitialized();
    if (!_firebaseAvailable) return;

    final authToken = await TokenStorage.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    try {
      await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/notification-token'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'token': fcmToken,
              'platform': Platform.operatingSystem,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Gagal sync FCM token: $e');
    }
  }

  static Future<void> unregisterToken() async {
    await ensureInitialized();
    if (!_firebaseAvailable) return;

    final authToken = await TokenStorage.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    try {
      await http
          .delete(
            Uri.parse('${AppConstants.baseUrl}/notification-token'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'token': fcmToken}),
          )
          .timeout(const Duration(seconds: 10));
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Gagal hapus FCM token: $e');
    }
  }

  static Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Pesan baru';
    final body = notification?.body ?? message.data['body'] ?? '';

    const androidDetails = AndroidNotificationDetails(
      'admin_messages',
      'Pesan Admin',
      channelDescription: 'Notifikasi pesan baru dari admin',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }
}
