// import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class NativeAlarmService {
//   static const MethodChannel _channel = MethodChannel('com.app.native_alarm');
//
//   /// Initialize the native alarm service
//   static Future<void> initialize() async {
//     try {
//       await _channel.invokeMethod('initialize');
//       print("Native alarm service initialized");
//     } catch (e) {
//       print("Error initializing native alarm service: $e");
//     }
//   }
//
//   /// Request necessary permissions
//   static Future<bool> requestPermissions() async {
//     try {
//       // Request alarm permission for Android 12+
//       if (await Permission.scheduleExactAlarm.isDenied) {
//         await Permission.scheduleExactAlarm.request();
//       }
//
//       // Request notification permission
//       if (await Permission.notification.isDenied) {
//         await Permission.notification.request();
//       }
//
//       return await Permission.notification.isGranted;
//     } catch (e) {
//       print("Error requesting permissions: $e");
//       return false;
//     }
//   }
//
//   /// Set alarm using device's built-in alarm system
//   static Future<bool> setDeviceAlarm({
//     required int id,
//     required String title,
//     required String message,
//     required DateTime scheduledTime,
//     int interval = 8,
//   }) async {
//     try {
//       final Map<String, dynamic> params = {
//         'id': id,
//         'title': title,
//         'message': message,
//         'hour': scheduledTime.hour,
//         'minute': scheduledTime.minute,
//         'interval': interval,
//         'timestamp': scheduledTime.millisecondsSinceEpoch,
//       };
//
//       final bool result = await _channel.invokeMethod('setAlarm', params);
//       print("Device alarm set: $result");
//       return result;
//     } catch (e) {
//       print("Error setting device alarm: $e");
//       return false;
//     }
//   }
//
//   /// Cancel device alarm
//   static Future<bool> cancelDeviceAlarm(int id) async {
//     try {
//       final bool result = await _channel.invokeMethod('cancelAlarm', {'id': id});
//       print("Device alarm cancelled: $result");
//       return result;
//     } catch (e) {
//       print("Error cancelling device alarm: $e");
//       return false;
//     }
//   }
//
//   /// Check if alarm is set
//   static Future<bool> isAlarmSet(int id) async {
//     try {
//       final bool result = await _channel.invokeMethod('isAlarmSet', {'id': id});
//       return result;
//     } catch (e) {
//       print("Error checking alarm status: $e");
//       return false;
//     }
//   }
//
//   /// Get all active alarms
//   static Future<List<Map<String, dynamic>>> getActiveAlarms() async {
//     try {
//       final List<dynamic> result = await _channel.invokeMethod('getActiveAlarms');
//       return result.cast<Map<String, dynamic>>();
//     } catch (e) {
//       print("Error getting active alarms: $e");
//       return [];
//     }
//   }
//
//   /// Open device alarm app
//   static Future<bool> openAlarmApp() async {
//     try {
//       final bool result = await _channel.invokeMethod('openAlarmApp');
//       return result;
//     } catch (e) {
//       print("Error opening alarm app: $e");
//       return false;
//     }
//   }
// }