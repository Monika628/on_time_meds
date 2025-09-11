import 'dart:io';
import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_time_meds/utils/alarm_service.dart';
import '../model/pill_model.dart';

class UpdatePillScreen extends StatefulWidget {
  final PillModel pill;

  const UpdatePillScreen({super.key, required this.pill});

  @override
  State<UpdatePillScreen> createState() => _UpdatePillScreenState();
}

class _UpdatePillScreenState extends State<UpdatePillScreen> {
  final TextEditingController _pillNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  TimeOfDay? _selectedTime;
  final List<int> _selectedTypeIndices = [];
  int _interval = 8;
  bool _isLoading = false;

  final List<Map<String, dynamic>> medicineTypes = [
    {"icon": Icons.local_pharmacy, "label": "Bottle"},
    {"icon": Icons.medication, "label": "Pill"},
    {"icon": Icons.vaccines, "label": "Syringe"},
    {"icon": Icons.block, "label": "Tablet"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAlarmService();
    _loadExistingPillData();
  }

  /// Initialize alarm service
  Future<void> _initializeAlarmService() async {
    try {
      await AlarmService.initialize();
      // Request permissions for Android 13+
      await AlarmService.requestPermissions();
    } catch (e) {
      print("Error initializing alarm service: $e");
    }
  }

  /// Load existing pill data for editing
  void _loadExistingPillData() {
    print("Loading existing pill data: ${widget.pill.pillName}");
    _pillNameController.text = widget.pill.pillName;
    _dosageController.text = widget.pill.dosage ?? '';
    _selectedTime = TimeOfDay.fromDateTime(widget.pill.time);
    _interval = widget.pill.interval ?? 8;

    // Load selected medicine types
    for (int i = 0; i < medicineTypes.length; i++) {
      if (widget.pill.types?.contains(medicineTypes[i]['label']) ?? false) {
        _selectedTypeIndices.add(i);
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      print("Selected time: ${picked.format(context)}");
    }
  }

  /// Validate form inputs
  bool _validateForm() {
    if (_pillNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a medicine name');
      return false;
    }

    if (_dosageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter dosage');
      return false;
    }

    if (_selectedTypeIndices.isEmpty) {
      _showErrorSnackBar('Please select at least one medicine type');
      return false;
    }

    if (_selectedTime == null) {
      _showErrorSnackBar('Please select a reminder time');
      return false;
    }

    return true;
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Update pill data in SharedPreferences
  Future<void> _updatePillInPreferences(PillModel pill) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing pills
      final String? pillsJson = prefs.getString('pills');
      List<PillModel> pills = [];

      if (pillsJson != null) {
        final List<dynamic> pillsData = jsonDecode(pillsJson);
        pills = pillsData.map((data) => PillModel.fromJson(data)).toList();
      }

      // Remove old pill and add updated one
      pills.removeWhere((p) => p.id == widget.pill.id);
      pills.add(pill);

      // Save back to preferences
      final String updatedPillsJson = jsonEncode(pills.map((p) => p.toJson()).toList());
      await prefs.setString('pills', updatedPillsJson);

      print("Pill updated in SharedPreferences successfully");
    } catch (e) {
      print("Error updating pill in SharedPreferences: $e");
      throw e;
    }
  }

  /// Set device alarm using Android Intent
  void setDeviceAlarm({required int hour, required int minutes, required String msg}) {
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.HOUR': hour,
          'android.intent.extra.alarm.MINUTES': minutes,
          'android.intent.extra.alarm.MESSAGE': msg,
        },
      );
      intent.launch();
    }
  }

  /// Main update function that handles both alarm and data saving
  void _updateReminder() async {
    print("Update button tapped");

    if (_isLoading) return;

    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // If the scheduled time is in the past, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        print("Scheduled time adjusted to tomorrow: $scheduledTime");
      }

      // Use existing pill ID
      final pill = PillModel(
        id: widget.pill.id,
        pillName: _pillNameController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: scheduledTime,
        types: _selectedTypeIndices
            .map((i) => medicineTypes[i]["label"] as String)
            .toList(),
        interval: _interval,
      );

      print("Pill Model Updated: ${pill.pillName}, ID: ${pill.id}, Time: $scheduledTime, Interval: $_interval");

      // Update in SharedPreferences
      await _updatePillInPreferences(pill);

      // Set device alarm
      setDeviceAlarm(
          hour: _selectedTime!.hour,
          minutes: _selectedTime!.minute,
          msg: "Pill Reminder: ${pill.pillName}"
      );

      // Cancel existing alarm
      print("Cancelling existing alarm with ID: ${widget.pill.id}");
      await AlarmService.cancelAlarm(widget.pill.id);
      await Future.delayed(const Duration(milliseconds: 500));

      // Schedule new alarm
      await AlarmService.scheduleAlarm(
        id: pill.id,
        title: "Pill Reminder 💊",
        body: "Time to take your medicine: ${pill.pillName}",
        scheduledTime: scheduledTime,
        interval: _interval,
      );

      print("Alarm updated successfully with ID: ${pill.id}");

      _showSuccessSnackBar('Pill reminder updated successfully!');

      // Return to previous screen with the updated pill data
      Navigator.pop(context, pill);

    } catch (e) {
      print("Error updating alarm: $e");

      String errorMessage = 'Failed to update reminder';
      if (e.toString().contains('Missing type parameter')) {
        errorMessage = 'Notification system error. Please restart the app and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Please enable notification permissions in settings';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Cancel alarm with confirmation
  Future<void> _cancelAlarm() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Alarm'),
        content: const Text('Are you sure you want to cancel this alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AlarmService.cancelAlarm(widget.pill.id);

        // Remove from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final String? pillsJson = prefs.getString('pills');
        if (pillsJson != null) {
          final List<dynamic> pillsData = jsonDecode(pillsJson);
          List<PillModel> pills = pillsData.map((data) => PillModel.fromJson(data)).toList();

          pills.removeWhere((p) => p.id == widget.pill.id);

          final String updatedPillsJson = jsonEncode(pills.map((p) => p.toJson()).toList());
          await prefs.setString('pills', updatedPillsJson);
        }

        _showSuccessSnackBar('Alarm cancelled successfully');
        Navigator.pop(context, 'deleted'); // Return signal that pill was deleted
      } catch (e) {
        print("Error cancelling alarm: $e");
        _showErrorSnackBar('Failed to cancel alarm');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orangeAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pill'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _cancelAlarm,
            tooltip: 'Delete Pill',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Medicine Name *"),
            _buildTextField(_pillNameController, "Enter medicine name"),

            _buildLabel("Dosage *"),
            _buildTextField(_dosageController, "Enter dosage (e.g., 500mg)", isNumber: false),

            _buildLabel("Medicine Type *"),
            const SizedBox(height: 10),
            _buildMedicineTypeSelector(primaryColor),

            _buildLabel("Dose Interval (hours) *"),
            _buildIntervalSelector(primaryColor),

            _buildLabel("Reminder Time *"),
            const SizedBox(height: 6),
            _buildTimeSelector(primaryColor),

            const SizedBox(height: 30),
            _buildUpdateButton(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildMedicineTypeSelector(Color primaryColor) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(medicineTypes.length, (index) {
        final selected = _selectedTypeIndices.contains(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              selected
                  ? _selectedTypeIndices.remove(index)
                  : _selectedTypeIndices.add(index);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? primaryColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  medicineTypes[index]["icon"],
                  size: 28,
                  color: selected ? primaryColor : Colors.grey,
                ),
                const SizedBox(height: 6),
                Text(
                  medicineTypes[index]["label"],
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? primaryColor : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIntervalSelector(Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: _interval,
            items: List.generate(
              24,
                  (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}'),
              ),
            ),
            onChanged: (value) => setState(() => _interval = value ?? 8),
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'hours',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(Color primaryColor) {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Select reminder time',
              style: TextStyle(
                fontSize: 16,
                color: _selectedTime != null ? Colors.black : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.access_time,
              color: primaryColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        )
            : const Text(
          'Update Reminder',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pillNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }
}