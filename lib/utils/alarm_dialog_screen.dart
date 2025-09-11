import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_time_meds/utils/alarm_service.dart';
import 'package:on_time_meds/utils/ringtone_service.dart';
import '../model/pill_model.dart';

class AlarmDialogScreen extends StatefulWidget {
  final PillModel pill;
  final VoidCallback onAlarmStopped;

  const AlarmDialogScreen({
    super.key,
    required this.pill,
    required this.onAlarmStopped,
  });

  @override
  State<AlarmDialogScreen> createState() => _AlarmDialogScreenState();
}

class _AlarmDialogScreenState extends State<AlarmDialogScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late String _currentTime;
  late String _alarmTime;

  @override
  void initState() {
    super.initState();

    // Get current time and alarm time
    final now = DateTime.now();
    _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _alarmTime = '${widget.pill.time.hour.toString().padLeft(2, '0')}:${widget.pill.time.minute.toString().padLeft(2, '0')}';

    _pulseController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _rotationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    // Enhanced haptic feedback
    _startContinuousVibration();
  }

  void _startContinuousVibration() async {
    // Initial strong vibration
    HapticFeedback.heavyImpact();

    // Continue vibrating every 2 seconds until alarm is stopped
    _vibratePattern();
  }

  void _vibratePattern() async {
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            _vibratePattern(); // Repeat the pattern
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _stopAlarm() async {
    // Convert pill ID to string
    //await AlarmService.stopAlarm(widget.pill.id.toString());
    await AlarmService.stopAlarm(widget.pill.id);

    widget.onAlarmStopped();
    if (mounted) Navigator.of(context).pop();
  }

  void _snoozeAlarm() async {
    await AlarmService.snoozeAlarm(
      widget.pill.id, // ✅ This is int
      "Pill Reminder 💊",
      "Time to take your pill: ${widget.pill.pillName}",
    );
    widget.onAlarmStopped();
    if (mounted) Navigator.of(context).pop();
  }


  void _showRingtoneSettings() {
    showDialog(
      context: context,
      builder: (context) => RingtoneSelectionDialog(
        currentRingtone: widget.pill.ringtone ?? 'Default',
        onRingtoneSelected: (ringtone) {
          // Update the pill's ringtone
          _updatePillRingtone(ringtone);
        },
      ),
    );
  }

  void _updatePillRingtone(String ringtone) async {
    // Update the pill model with new ringtone - convert pill ID to string
    await RingtoneService.updatePillRingtone(widget.pill.id.toString(), ringtone);

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ringtone updated to: $ringtone'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar with back button and settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('⚠️ Warning'),
                            content: const Text('Alarm is still active! Please take your medicine or snooze the alarm.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.red),
                      tooltip: 'Ringtone Settings',
                      onPressed: _showRingtoneSettings,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade100, Colors.orange.shade100],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: AnimatedBuilder(
                              animation: _rotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationAnimation.value * 2 * 3.14159,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.medication, size: 60, color: Colors.red),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // Title with current time
                      Column(
                        children: [
                          const Text(
                            'PILL REMINDER',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current Time: $_currentTime',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Pill Info
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              pill.pillName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (pill.dosage != null && pill.dosage!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Dosage: ${pill.dosage} mg',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'Scheduled Time: $_alarmTime',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                            // Current ringtone display
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.volume_up, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Ringtone: ${pill.ringtone ?? 'Default'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Snooze
                          GestureDetector(
                            onTap: _snoozeAlarm,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.snooze, size: 40, color: Colors.white),
                                  SizedBox(height: 8),
                                  Text('Snooze', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('5 min', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          // Stop
                          GestureDetector(
                            onTap: _stopAlarm,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 40, color: Colors.white),
                                  SizedBox(height: 8),
                                  Text('Taken', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('Done', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Tap "Taken" when you\'ve taken your medicine\nor "Snooze" for 5 minutes',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Improved Ringtone Selection Dialog
class RingtoneSelectionDialog extends StatefulWidget {
  final String currentRingtone;
  final Function(String) onRingtoneSelected;

  const RingtoneSelectionDialog({
    super.key,
    required this.currentRingtone,
    required this.onRingtoneSelected,
  });

  @override
  State<RingtoneSelectionDialog> createState() => _RingtoneSelectionDialogState();
}

class _RingtoneSelectionDialogState extends State<RingtoneSelectionDialog> {
  late String selectedRingtone;
  String? currentlyPlayingRingtone;
  String? justPlayedRingtone;

  final List<RingtoneOption> ringtones = [
    RingtoneOption(
      name: 'Default',
      description: 'Default system alarm sound',
      icon: Icons.alarm,
      assetPath: 'assets/sounds/twirling-intime-lenovo-k8-note-alarm-tone-41440.mp3',
    ),
    RingtoneOption(
      name: 'Gentle Bell',
      description: 'Soft and pleasant bell sound',
      icon: Icons.notifications_none,
      assetPath: 'assets/sounds/download-ringtone-807-funonsite-com-40938.mp3',
    ),
    RingtoneOption(
      name: 'Medical Alert',
      description: 'Professional medical beep sound',
      icon: Icons.medical_services,
      assetPath: 'assets/sounds/wakeup-alarm-tone-21497.mp3',
    ),
    RingtoneOption(
      name: 'Chimes',
      description: 'Peaceful wind chimes',
      icon: Icons.music_note,
      assetPath: 'assets/sounds/cdoctors-office-25670.mp3',
    ),
    RingtoneOption(
      name: 'Buzzer',
      description: 'Strong attention-grabbing buzzer',
      icon: Icons.vibration,
      assetPath: 'assets/sounds/doorbell-26510.mp3',
    ),
    RingtoneOption(
      name: 'Melody',
      description: 'Soothing musical melody',
      icon: Icons.library_music,
      assetPath: 'assets/sounds/vibration-rintone-13061.mp3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedRingtone = widget.currentRingtone;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.volume_up, color: Colors.red),
          SizedBox(width: 8),
          Text('Select Ringtone'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Currently Selected: $selectedRingtone",
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: ringtones.length,
              itemBuilder: (context, index) {
                final ringtone = ringtones[index];
                final isSelected = selectedRingtone == ringtone.name;
                final isPlaying = currentlyPlayingRingtone == ringtone.name;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: isSelected ? 4 : 1,
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ringtone.icon,
                        color: isSelected ? Colors.red : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      ringtone.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.red : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      ringtone.description,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Play/Stop preview button
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            color: isPlaying ? Colors.red : Colors.grey.shade600,
                          ),
                          onPressed: () => _togglePreviewSound(ringtone),
                          tooltip: isPlaying ? 'Stop Preview' : 'Play Preview',
                        ),

                        // Show select button only if this is just played
                        if (justPlayedRingtone == ringtone.name)
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            tooltip: "Select this",
                            onPressed: () {
                              setState(() {
                                selectedRingtone = ringtone.name;
                              });
                              HapticFeedback.selectionClick();
                            },
                          )
                        else if (isSelected)
                          const Icon(Icons.check, color: Colors.red)
                        else
                          Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (currentlyPlayingRingtone != null) {
              RingtoneService.stopPreviewSound();
            }
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (currentlyPlayingRingtone != null) {
              RingtoneService.stopPreviewSound();
            }
            widget.onRingtoneSelected(selectedRingtone);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _togglePreviewSound(RingtoneOption ringtone) {
    setState(() {
      if (currentlyPlayingRingtone == ringtone.name) {
        RingtoneService.stopPreviewSound();
        currentlyPlayingRingtone = null;
        justPlayedRingtone = null;
      } else {
        if (currentlyPlayingRingtone != null) {
          RingtoneService.stopPreviewSound();
        }
        RingtoneService.playPreviewSound(ringtone.assetPath);
        currentlyPlayingRingtone = ringtone.name;
        justPlayedRingtone = ringtone.name;

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && currentlyPlayingRingtone == ringtone.name) {
            setState(() {
              RingtoneService.stopPreviewSound();
              currentlyPlayingRingtone = null;
            });
          }
        });
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    if (currentlyPlayingRingtone != null) {
      RingtoneService.stopPreviewSound();
    }
    super.dispose();
  }
}


// Improved RingtoneOption class
class RingtoneOption {
  final String name;
  final String description;
  final IconData icon;
  final String assetPath;

  RingtoneOption({
    required this.name,
    required this.description,
    required this.icon,
    required this.assetPath,
  });
}