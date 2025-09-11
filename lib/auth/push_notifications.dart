//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// import '../main.dart';
//
//
// class PushNotifications {
//   static final _firebaseMessaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   // Notification Channel Configuration (Android)
//   static const String channelId = 'your_channel_id';
//   static const String channelName = 'your_channel_name';
//   static const String channelDescription = 'your_channel_description';
//
//   // Initialize Push Notifications
//   static Future init() async {
//     // Request notification permissions
//     await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     // Print device token for debugging
//     final token = await _firebaseMessaging.getToken();
//     print("Device token: $token");
//
//     // Create the notification channel (only required once)
//     const AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
//       channelId,
//       channelName,
//       description: channelDescription,
//       importance: Importance.max,
//     );
//
//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(androidNotificationChannel);
//   }
//
//   // Initialize local notifications
//   static Future localNotiInit() async {
//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
//
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsDarwin,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: onNotificationTap,
//     );
//   }
//
//   // Handle notification tap
//   static void onNotificationTap(NotificationResponse notificationResponse) {
//     if (navigatorKey.currentState != null) {
//       navigatorKey.currentState!.pushNamed("/message", arguments: notificationResponse.payload);
//     } else {
//       print("Navigator state is null");
//     }
//   }
//
//   // Show a simple notification
//   static Future showSimpleNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
//       channelId,
//       channelName,
//       channelDescription: channelDescription,
//       importance: Importance.max,
//       priority: Priority.high,
//       ticker: 'ticker',
//     );
//
//     const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
//
//     await _flutterLocalNotificationsPlugin.show(
//       0,
//       message.notification?.title,
//       message.notification?.body,
//       notificationDetails,
//       payload: message.data.toString(),
//     );
//   }
// }
