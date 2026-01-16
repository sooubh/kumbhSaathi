import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages silently
}

/// Notification service for Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize notifications
  Future<void> initialize() async {
    // Request notification permission (Android 13+ / iOS)
    final permissionStatus = await _requestNotificationPermission();

    if (!permissionStatus) {
      return; // User denied permission
    }

    // Request FCM permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Create notification channel for Android 8.0+
      await _createNotificationChannel();

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Get FCM token
      _fcmToken = await _messaging.getToken();

      // Save token to Firestore
      if (_fcmToken != null) {
        await _saveTokenToFirestore(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // Configure foreground notification handling
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Configure background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
  }

  /// Request notification permission for Android 13+
  Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    return false;
  }

  /// Create notification channel for Android 8.0+
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'kumbhsaathi_channel',
      'KumbhSaathi Notifications',
      description: 'Notifications for Kumbh Mela updates and alerts',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('fcm_tokens').doc(user.uid).set({
        'token': token,
        'platform': 'android', // or 'ios'
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error saving token - fail silently in production
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'KumbhSaathi',
        body: notification.body ?? '',
        data: data,
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kumbhsaathi_channel',
      'KumbhSaathi Notifications',
      channelDescription: 'Notifications for Kumbh Mela updates and alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data?.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to relevant screen based on payload
  }

  void _handleNotificationTap(RemoteMessage message) {
    // TODO: Navigate based on message data
  }

  /// Subscribe to topic (for Kumbh Mela updates)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Send notification to all users (Admin only)
  Future<void> sendNotificationToAll({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'type': 'broadcast',
        'topic': 'all_users',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  /// Send lost person notification
  Future<void> sendLostPersonNotification({
    required String personId,
    required String personName,
    required String description,
    String? photoUrl,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': '⚠️ Lost Person Alert',
        'body': 'Help find $personName - $description',
        'data': {
          'type': 'lost_person',
          'personId': personId,
          'photoUrl': photoUrl ?? '',
        },
        'type': 'lost_person',
        'topic': 'all_users',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to send lost person alert: $e');
    }
  }

  /// Send Kumbh Mela update notification
  Future<void> sendKumbhUpdateNotification({
    required String title,
    required String body,
    String? eventId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': '🕉️ $title',
        'body': body,
        'data': {'type': 'kumbh_update', 'eventId': eventId ?? ''},
        'type': 'kumbh_update',
        'topic': 'kumbh_updates',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to send Kumbh update: $e');
    }
  }

  /// Send crowd level update notification
  Future<void> sendCrowdLevelNotification({
    required String ghatName,
    required String oldLevel,
    required String newLevel,
    String? customMessage,
  }) async {
    try {
      // Generate appropriate icon and message based on the new crowd level
      final String icon;
      final String defaultMessage;

      switch (newLevel.toLowerCase()) {
        case 'low':
          icon = '✅';
          defaultMessage = '$ghatName is now less crowded! Good time to visit.';
          break;
        case 'medium':
          icon = '📊';
          defaultMessage = '$ghatName has moderate crowd levels.';
          break;
        case 'high':
          icon = '⚠️';
          defaultMessage =
              '$ghatName is experiencing high crowd levels. Consider visiting later.';
          break;
        default:
          icon = '📍';
          defaultMessage = 'Crowd level updated at $ghatName';
      }

      final message = customMessage ?? defaultMessage;

      await _firestore.collection('notifications').add({
        'title': '$icon Crowd Update: $ghatName',
        'body': message,
        'data': {
          'type': 'crowd_update',
          'ghatName': ghatName,
          'oldLevel': oldLevel,
          'newLevel': newLevel,
        },
        'type': 'crowd_update',
        'topic': 'all_users',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to send crowd level notification: $e');
    }
  }
}
