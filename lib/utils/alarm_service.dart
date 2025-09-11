import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool _isAlarmPlaying = false;
  static int? _currentAlarmId;

  /// Getter to check if alarm is currently playing
  static bool get isAlarmPlaying => _isAlarmPlaying;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();

      // Android initialization settings with explicit type
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize with proper error handling
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      _isInitialized = true;
      print("Notification service initialized successfully");
    } catch (e) {
      print("Error initializing notification service: $e");
      rethrow;
    }
  }

  /// Handle notification tap
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print("Notification tapped: ${response.payload}");
    // Set alarm as playing when notification is received
    _isAlarmPlaying = true;
    if (response.payload != null) {
      _currentAlarmId = int.tryParse(response.payload!);
    }
  }

  /// Schedule an alarm with proper type safety
  static Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    int interval = 8,
  }) async {
    try {
      // Ensure initialization
      if (!_isInitialized) {
        await initialize();
      }

      // Convert ID to ensure it's within safe range
      final safeId = _convertToSafeId(id);
      print("Original ID: $id");
      print("Safe ID: $safeId");

      // Convert to timezone-aware DateTime
      final tz.Location local = tz.getLocation('Asia/Kolkata'); // Adjust for your timezone
      final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledTime, local);

      print("Scheduling notification for: $scheduledTime");
      print("TZ DateTime: $scheduledTZ");

      // Android notification details with explicit types
      const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        'alarm_channel',
        'Pill Reminders',
        channelDescription: 'Notifications for pill reminders',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Pill Reminder',
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );

      // iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Schedule the notification with explicit type casting
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        safeId, // Ensure this is int
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: safeId.toString(), // Convert to string for payload
      );

      print("Alarm scheduled successfully with ID: $safeId");

      // Schedule repeating alarms if interval is set
      if (interval > 0) {
        await _scheduleRepeatingAlarms(
          safeId,
          title,
          body,
          scheduledTZ,
          interval,
          notificationDetails,
        );
      }

    } catch (e) {
      print("Error scheduling alarm: $e");
      rethrow;
    }
  }

  /// Schedule repeating alarms
  static Future<void> _scheduleRepeatingAlarms(
      int baseId,
      String title,
      String body,
      tz.TZDateTime firstAlarm,
      int intervalHours,
      NotificationDetails notificationDetails,
      ) async {
    try {
      // Schedule next few alarms (e.g., next 7 days)
      final int totalAlarms = (24 * 7) ~/ intervalHours; // 7 days worth

      for (int i = 1; i <= totalAlarms; i++) {
        final nextAlarmTime = firstAlarm.add(Duration(hours: intervalHours * i));
        final nextId = _generateSequentialId(baseId, i);

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          nextId,
          title,
          body,
          nextAlarmTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          payload: nextId.toString(),
        );

        print("Scheduled repeating alarm $i with ID: $nextId at $nextAlarmTime");
      }
    } catch (e) {
      print("Error scheduling repeating alarms: $e");
    }
  }

  /// Stop an alarm
  static Future<void> stopAlarm(int id) async {
    try {
      final safeId = _convertToSafeId(id);
      print("Stopping alarm with ID: $id -> $safeId");

      // Cancel the notification
      await _flutterLocalNotificationsPlugin.cancel(safeId);

      // Reset alarm playing state
      _isAlarmPlaying = false;
      _currentAlarmId = null;

      print("Alarm stopped successfully");

    } catch (e) {
      print("Error stopping alarm: $e");
      // Don't rethrow here to prevent app crashes
    }
  }

  /// Snooze an alarm for a specified duration (default 5 minutes)
  static Future<void> snoozeAlarm(
      int id,
      String title,
      String body,
      {Duration snoozeDuration = const Duration(minutes: 5)}
      ) async {
    try {
      final safeId = _convertToSafeId(id);
      print("Snoozing alarm with ID: $id -> $safeId for ${snoozeDuration.inMinutes} minutes");

      // First, stop the current alarm
      await stopAlarm(id);

      // Schedule a new alarm for the snooze duration
      final snoozeTime = DateTime.now().add(snoozeDuration);

      // Generate a new ID for the snoozed alarm (add 10000 to avoid conflicts)
      final snoozeId = safeId + 10000;

      await scheduleAlarm(
        id: snoozeId,
        title: title,
        body: body,
        scheduledTime: snoozeTime,
        interval: 0, // No repeating for snoozed alarms
      );

      print("Alarm snoozed successfully. New alarm scheduled for: $snoozeTime");

    } catch (e) {
      print("Error snoozing alarm: $e");
      rethrow;
    }
  }

  /// Cancel an alarm
  static Future<void> cancelAlarm(int id) async {
    try {
      final safeId = _convertToSafeId(id);
      print("Cancelling alarm with ID: $id -> $safeId");

      await _flutterLocalNotificationsPlugin.cancel(safeId);
      print("Alarm cancelled successfully");

      // Also cancel related repeating alarms
      await _cancelRepeatingAlarms(safeId);

      // Reset alarm playing state if this was the current alarm
      if (_currentAlarmId == safeId) {
        _isAlarmPlaying = false;
        _currentAlarmId = null;
      }

    } catch (e) {
      print("Error cancelling alarm: $e");
      // Don't rethrow here to prevent app crashes
    }
  }

  /// Cancel repeating alarms
  static Future<void> _cancelRepeatingAlarms(int baseId) async {
    try {
      // Cancel next 168 possible alarms (24*7 hours)
      for (int i = 1; i <= 168; i++) {
        final nextId = _generateSequentialId(baseId, i);
        await _flutterLocalNotificationsPlugin.cancel(nextId);
      }
      print("Cancelled repeating alarms for base ID: $baseId");
    } catch (e) {
      print("Error cancelling repeating alarms: $e");
    }
  }

  /// Get all pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print("Error getting pending notifications: $e");
      return [];
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllAlarms() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _isAlarmPlaying = false;
      _currentAlarmId = null;
      print("All alarms cancelled");
    } catch (e) {
      print("Error cancelling all alarms: $e");
    }
  }

  /// Convert large IDs to safe 32-bit integers
  static int _convertToSafeId(int originalId) {
    // If ID is already within safe range, return as is
    if (originalId <= 2147483647 && originalId >= -2147483648) {
      return originalId;
    }

    // Convert large ID to safe range using modulo
    final safeId = originalId.abs() % 2147483647;
    print("Converting ID: $originalId -> $safeId");
    return safeId;
  }

  /// Generate sequential ID for repeating alarms
  static int _generateSequentialId(int baseId, int sequence) {
    // Ensure the generated ID doesn't overflow
    final seqId = (baseId + sequence) % 2147483647;
    return seqId;
  }

  /// Request permissions (especially for Android 13+)
  static Future<bool> requestPermissions() async {
    try {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    } catch (e) {
      print("Error requesting permissions: $e");
      return false;
    }
  }

  /// Check if a specific alarm is currently active
  static bool isAlarmActive(int id) {
    final safeId = _convertToSafeId(id);
    return _isAlarmPlaying && _currentAlarmId == safeId;
  }

  /// Manually set alarm playing state (useful for testing)
  static void setAlarmPlaying(bool playing, {int? alarmId}) {
    _isAlarmPlaying = playing;
    _currentAlarmId = playing ? alarmId : null;
  }
}