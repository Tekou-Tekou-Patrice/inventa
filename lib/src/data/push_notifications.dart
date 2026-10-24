import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'plantation_api.dart';

class PushNotifications {
  PushNotifications._();

  static const _webVapidKey = String.fromEnvironment(
    'INVENTA_FIREBASE_WEB_VAPID_KEY',
  );
  static const _channel = AndroidNotificationChannel(
    'inventa_activity',
    'Activité Inventa',
    description: 'Demandes, paie, dépenses et approvisionnements.',
    importance: Importance.high,
  );
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static bool _localNotificationsInitialized = false;
  static PlantationApi? _api;
  static String? _registeredToken;

  static Future<void> registerDevice(PlantationApi api) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        !kIsWeb) {
      return;
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _api = api;
    await _initializeLocalNotifications();
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    if (kIsWeb && _webVapidKey.isEmpty) {
      throw const ApiException(
        'La clé Web Push VAPID doit être configurée avec '
        '--dart-define=INVENTA_FIREBASE_WEB_VAPID_KEY.',
      );
    }
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    await _tokenSubscription?.cancel();
    final registration = Completer<String>();
    _tokenSubscription = messaging.onRegistered.listen(
      (token) {
        if (registration.isCompleted) {
          unawaited(_registerToken(token));
        } else {
          registration.complete(token);
        }
      },
      onError: (Object error) {
        if (!registration.isCompleted) registration.completeError(error);
        debugPrint('Firebase registration failed: $error');
      },
    );
    await messaging.register(
      vapidKey: kIsWeb ? _webVapidKey : null,
      serviceWorkerScriptPath: kIsWeb ? '/firebase-messaging-sw.js' : null,
    );
    final token = await registration.future.timeout(
      const Duration(seconds: 30),
    );
    await _registerToken(token);
  }

  static Future<void> unregisterDevice(PlantationApi api) async {
    try {
      final token = _registeredToken;
      if (token != null && token.isNotEmpty && api.isAuthenticated) {
        await api.request(
          'DELETE',
          '/api/push/devices',
          body: {'token': token},
        );
      }
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.unregister();
      }
    } finally {
      await _foregroundSubscription?.cancel();
      await _tokenSubscription?.cancel();
      _foregroundSubscription = null;
      _tokenSubscription = null;
      _api = null;
      _registeredToken = null;
    }
  }

  static Future<void> _registerToken(String token) async {
    final api = _api;
    if (api == null || !api.isAuthenticated) return;
    await api.request(
      'POST',
      '/api/push/devices',
      body: {
        'token': token,
        'platform': kIsWeb
            ? 'web'
            : defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      },
    );
    _registeredToken = token;
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    _localNotificationsInitialized = true;
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;
    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'inventa_activity',
          'Activité Inventa',
          channelDescription: 'Demandes, paie, dépenses et approvisionnements.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
