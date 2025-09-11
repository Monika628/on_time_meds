import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:wakelock_plus/wakelock_plus.dart';

class BackgroundAlarmService {
  static const String _portName = 'alarm_port';
  static const String _alarmDataKey = 'alarm_data';
  static const String _activeAlarmKey = 'active_alarm';

  static FlutterLocalNotificationsPlugin? _notifications;
  static bool _isInitialized = false;
  static bool _isAlarmActive = false;

  // Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _notifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications!.initialize(settings);
    await AndroidAlarmManager.initialize();

    _isInitialized = true;
  }

  // Stop a specific alarm
  static Future<void> stopAlarm(int alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cancel the alarm
      await AndroidAlarmManager.cancel(alarmId);

      // Cancel notifications
      await _notifications?.cancel(alarmId);
      await _notifications?.cancel(alarmId + 1000); // For snooze notification

      // Remove alarm data
      await prefs.remove('alarm_$alarmId');

      // Update active alarm status
      final activeAlarmId = prefs.getInt('active_alarm_id');
      if (activeAlarmId == alarmId) {
        _isAlarmActive = false;
        await WakelockPlus.disable();
        await prefs.remove(_activeAlarmKey);
        await prefs.remove('active_alarm_id');
      }

      print('✅ Alarm $alarmId stopped');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
  }

  // Snooze an alarm
  static Future<void> snoozeAlarm(int alarmId, int snoozeMinutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cancel current alarm
      await AndroidAlarmManager.cancel(alarmId);
      await _notifications?.cancel(alarmId);

      // Calculate snooze time
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));

      // Get original alarm data
      final alarmDataJson = prefs.getString('alarm_$alarmId');
      if (alarmDataJson != null) {
        final alarmData = json.decode(alarmDataJson) as Map<String, dynamic>;

        // Update alarm time for snooze
        alarmData['alarmTime'] = snoozeTime.millisecondsSinceEpoch;
        alarmData['isSnooze'] = true;

        // Save updated alarm data
        await prefs.setString('alarm_$alarmId', json.encode(alarmData));

        // Schedule snooze alarm
        final now = DateTime.now();
        final durationUntilAlarm = snoozeTime.difference(now);

        await AndroidAlarmManager.oneShot(
          durationUntilAlarm,
          alarmId,
          _alarmCallback,
          exact: true,
          wakeup: true,
        );


        // Show snooze notification
        await _showSnoozeNotification(alarmId, alarmData, snoozeTime);

        print('✅ Alarm $alarmId snoozed for $snoozeMinutes minutes');
      }
    } catch (e) {
      print('❌ Error snoozing alarm: $e');
    }
  }

  // Show snooze notification
  static Future<void> _showSnoozeNotification(
      int alarmId,
      Map<String, dynamic> alarmData,
      DateTime snoozeTime,
      ) async {
    final pillName = alarmData['pillName'] as String;
    final formattedTime = '${snoozeTime.hour.toString().padLeft(2, '0')}:${snoozeTime.minute.toString().padLeft(2, '0')}';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'snooze_channel',
      'Snooze Notifications',
      channelDescription: 'Notifications for snoozed alarms',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications?.show(
      alarmId + 1000, // Use different ID for snooze notification
      'Medicine Reminder Snoozed',
      '$pillName reminder snoozed until $formattedTime',
      details,
    );
  }

  // Alarm callback function (static method for background execution)
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(int id, Map<String, dynamic> params) async {
    print('🔔 Alarm callback triggered for ID: $id');

    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmDataJson = prefs.getString('alarm_$id');

      if (alarmDataJson != null) {
        final alarmData = json.decode(alarmDataJson) as Map<String, dynamic>;

        // Set active alarm
        _isAlarmActive = true;
        await prefs.setBool(_activeAlarmKey, true);
        await prefs.setInt('active_alarm_id', id);

        // Enable wakelock
        await WakelockPlus.enable();

        // Show notification
        await _showAlarmNotification(id, alarmData);

        // Send data to main isolate if needed
        _sendToMainIsolate(alarmData);
      }
    } catch (e) {
      print('❌ Error in alarm callback: $e');
    }
  }

  // Show alarm notification
  static Future<void> _showAlarmNotification(int id, Map<String, dynamic> alarmData) async {
    final pillName = alarmData['pillName'] as String;
    final dosage = alarmData['dosage'] as String?;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Medicine Alarms',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    final dosageText = dosage != null && dosage.isNotEmpty ? ' - $dosage mg' : '';

    await _notifications?.show(
      id,
      'Medicine Time!',
      'Take your $pillName$dosageText',
      details,
    );
  }

  // Send data to main isolate
  static void _sendToMainIsolate(Map<String, dynamic> alarmData) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(_portName);
    sendPort?.send(alarmData);
  }

  // Cancel all alarms
  static Future<void> cancelAllAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('alarm_')) {
          final id = int.tryParse(key.substring(6));
          if (id != null) {
            await AndroidAlarmManager.cancel(id);
            await _notifications?.cancel(id);
            await _notifications?.cancel(id + 1000); // For snooze
            await prefs.remove(key);
          }
        }
      }

      _isAlarmActive = false;
      await WakelockPlus.disable(); // Fixed: Changed from Wakelock to WakelockPlus
      await prefs.remove(_activeAlarmKey);
      await prefs.remove('active_alarm_id');

      print('✅ All alarms cancelled');
    } catch (e) {
      print('❌ Error cancelling alarms: $e');
    }
  }
}

// Enhanced Alarm Dialog for background alarms
class BackgroundAlarmDialog extends StatefulWidget {
  final Map<String, dynamic> alarmData;
  final VoidCallback onAlarmStopped;

  const BackgroundAlarmDialog({
    super.key,
    required this.alarmData,
    required this.onAlarmStopped,
  });

  @override
  State<BackgroundAlarmDialog> createState() => _BackgroundAlarmDialogState();
}

class _BackgroundAlarmDialogState extends State<BackgroundAlarmDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Keep screen on
    WakelockPlus.enable(); // Fixed: Changed from Wakelock to WakelockPlus

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseController.repeat(reverse: true);
    _startShaking();
  }

  void _startShaking() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _shakeController.forward().then((_) {
          _shakeController.reverse().then((_) {
            if (mounted) _startShaking();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    WakelockPlus.disable(); // Already correct
    super.dispose();
  }

  void _stopAlarm() async {
    final id = widget.alarmData['id'] as int;
    await BackgroundAlarmService.stopAlarm(id);
    widget.onAlarmStopped();
    if (mounted) Navigator.of(context).pop();
  }

  void _snoozeAlarm() async {
    final id = widget.alarmData['id'] as int;
    await BackgroundAlarmService.snoozeAlarm(id, 5);
    widget.onAlarmStopped();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pillName = widget.alarmData['pillName'] as String;
    final dosage = widget.alarmData['dosage'] as String?;
    final alarmTime = DateTime.fromMillisecondsSinceEpoch(
      widget.alarmData['alarmTime'] as int,
    );
    final formattedTime = '${alarmTime.hour.toString().padLeft(2, '0')}:${alarmTime.minute.toString().padLeft(2, '0')}';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade900,
                        Colors.red.shade600,
                        Colors.orange.shade600,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large pulsing icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.8),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.medication,
                                size: 80,
                                color: Colors.red,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        '⏰ MEDICINE TIME!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Pill info
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              pillName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (dosage != null && dosage.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Dosage: $dosage mg',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Scheduled: $formattedTime',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Snooze button
                          GestureDetector(
                            onTap: _snoozeAlarm,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.snooze,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Snooze',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '5 min',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Stop button
                          GestureDetector(
                            onTap: _stopAlarm,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Taken',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Done',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        'Phone will keep alarming until you respond',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}