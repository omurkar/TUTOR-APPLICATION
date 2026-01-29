import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 1. Initialize Notifications
  static Future<void> initialize() async {
    // Request Permission (Required for iOS/Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Setup Local Notifications (for foreground messages)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    // Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });
  }

  // 2. Show Notification when App is Open
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (message.notification != null) {
      await _localNotifications.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  // 3. Save Device Token to Firestore (Call this after Login)
  static Future<void> saveTokenToDatabase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get the unique device token
    String? token = await _firebaseMessaging.getToken();

    if (token != null) {
      // Save it to the user's profile
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
      print("FCM Token Saved: $token");
    }
  }
}