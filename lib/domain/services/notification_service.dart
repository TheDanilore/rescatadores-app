import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification services
  Future<void> initialize() async {
    try {
      // Initialize timezone configurations
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Lima'));

      // Configurar notificaciones locales antes de permisos
      await _configureLocalNotifications();

      // Solicitar permisos después de configurar notificaciones
      await requestPermissions();

      // Manejo de token
      await _handleTokenManagement();

      // Setup Firebase Messaging listeners
      _setupMessagingListeners();
    } catch (e) {
      print('Notification initialization error: $e');
    }
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: kIsWeb ? false : true, // Desactiva provisional en web
      criticalAlert: true, // Habilitar alertas críticas si es posible
    );

    print(
      settings.authorizationStatus == AuthorizationStatus.authorized
          ? '✅ Permisos de notificación concedidos'
          : '⚠️ Permisos de notificación denegados',
    );
  }

  /// Configure local notifications
  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Add navigation logic based on payload
  }

  /// Setup Firebase Messaging listeners
  void _setupMessagingListeners() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageOpen);
  }

  /// Handle token management
  Future<void> _handleTokenManagement() async {
    // Obtener el token inicial
    String? initialToken = await _fcm.getToken();
    if (initialToken != null) {
      print('Initial FCM Token: $initialToken');
      await _saveTokenToDatabase(initialToken);
    }

    // Escuchar la renovación del token
    _fcm.onTokenRefresh.listen((newToken) async {
      if (newToken != null) {
        print('New FCM Token: $newToken');
        await _saveTokenToDatabase(newToken);
      }
    });

    // Guardar token en cambios de estado de autenticación
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        final token = await _fcm.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
        }
      }
    });
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'general_channel', // Asegúrate que coincida con el ID del canal
      'General Notifications',
      channelDescription: 'Notificaciones generales',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'ticker',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .set({
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'platform': kIsWeb ? 'web' : 'mobile',
          });

      print('✅ Token saved to Firestore');
    } catch (e) {
      print('⚠️ Error saving token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _showLocalNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? 'New message',
        payload: message.data['resource_id'],
      );
    }
  }

  /// Handle background message when app is opened
  void _handleBackgroundMessageOpen(RemoteMessage message) {
    print('Background message opened: ${message.messageId}');
    // Add navigation logic based on message
  }

  /// Static background message handler
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    print('Background message received: ${message.messageId}');
    // Additional background processing
  }
}
