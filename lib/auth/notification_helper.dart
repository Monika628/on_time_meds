// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationHelper {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   static Future<void> initialize() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const InitializationSettings initializationSettings =
//     InitializationSettings(android: initializationSettingsAndroid);
//
//     await _notificationsPlugin.initialize(initializationSettings);
//   }
//
//   static Future<void> showNotification({required String title, required String body}) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'channel_id',
//       'channel_name',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//
//     const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
//
//     await _notificationsPlugin.show(0, title, body, notificationDetails);
//   }
// }


import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print('Notification helper initialization error: $e');
    }
  }

  static Future<void> showNotification({required String title, required String body}) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(0, title, body, notificationDetails);
    } catch (e) {
      print('Show notification error: $e');
    }
  }
}
