// import 'dart:io';
//
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:flutter/material.dart';
// import 'package:on_time_meds/utils/alarm_service.dart';
// import '../model/pill_model.dart';
//
// class AddPillScreen extends StatefulWidget {
//   final PillModel? pill;
//
//   const AddPillScreen({super.key, this.pill});
//
//   @override
//   State<AddPillScreen> createState() => _AddPillScreenState();
// }
//
// class _AddPillScreenState extends State<AddPillScreen> {
//   final TextEditingController _pillNameController = TextEditingController();
//   final TextEditingController _dosageController = TextEditingController();
//   TimeOfDay? _selectedTime;
//   final List<int> _selectedTypeIndices = [];
//   int _interval = 8;
//   bool _isLoading = false;
//
//   final List<Map<String, dynamic>> medicineTypes = [
//     {"icon": Icons.local_pharmacy, "label": "Bottle"},
//     {"icon": Icons.medication, "label": "Pill"},
//     {"icon": Icons.vaccines, "label": "Syringe"},
//     {"icon": Icons.block, "label": "Tablet"},
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeAlarmService();
//     _loadExistingPillData();
//   }
//
//   /// Initialize alarm service
//   Future<void> _initializeAlarmService() async {
//     try {
//       await AlarmService.initialize();
//       // Request permissions for Android 13+
//       await AlarmService.requestPermissions();
//     } catch (e) {
//       print("Error initializing alarm service: $e");
//     }
//   }
//
//   /// Load existing pill data if editing
//   void _loadExistingPillData() {
//     if (widget.pill != null) {
//       print("Editing existing pill: ${widget.pill!.pillName}");
//       _pillNameController.text = widget.pill!.pillName;
//       _dosageController.text = widget.pill!.dosage ?? '';
//       _selectedTime = TimeOfDay.fromDateTime(widget.pill!.time);
//       _interval = widget.pill!.interval ?? 8;
//
//       // Load selected medicine types
//       for (int i = 0; i < medicineTypes.length; i++) {
//         if (widget.pill!.types?.contains(medicineTypes[i]['label']) ?? false) {
//           _selectedTypeIndices.add(i);
//         }
//       }
//     }
//   }
//
//   /// Generate a safe 32-bit integer ID with better collision avoidance
//   int _generateSafeId() {
//     final now = DateTime.now();
//
//     // Create a more unique ID using microseconds and pill name
//     final microTime = now.microsecondsSinceEpoch;
//     final nameHash = _pillNameController.text.isNotEmpty
//         ? _pillNameController.text.hashCode.abs()
//         : 0;
//
//     // Combine time and name hash, ensure it's positive and within 32-bit range
//     final combinedId = (microTime + nameHash).abs();
//     final safeId = combinedId % 2147483647;
//
//     print("Generated safe ID: $safeId");
//     return safeId;
//   }
//
//   Future<void> _pickTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime ?? TimeOfDay.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedTime = picked;
//       });
//       print("Selected time: ${picked.format(context)}");
//     }
//   }
//
//   /// Validate form inputs
//   bool _validateForm() {
//     if (_pillNameController.text.trim().isEmpty) {
//       _showErrorSnackBar('Please enter a medicine name');
//       return false;
//     }
//
//     if (_selectedTime == null) {
//       _showErrorSnackBar('Please select a reminder time');
//       return false;
//     }
//
//     return true;
//   }
//
//   /// Show error snackbar
//   void _showErrorSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   /// Show success snackbar
//   void _showSuccessSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   void _saveReminder() async {
//     print("Save button tapped");
//
//     if (_isLoading) return;
//
//     if (!_validateForm()) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final now = DateTime.now();
//       DateTime scheduledTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         _selectedTime!.hour,
//         _selectedTime!.minute,
//       );
//
//       // If the scheduled time is in the past, schedule for tomorrow
//       if (scheduledTime.isBefore(now)) {
//         scheduledTime = scheduledTime.add(const Duration(days: 1));
//         print("Scheduled time adjusted to tomorrow: $scheduledTime");
//       }
//
//       // Generate a safe ID for new pills, keep existing ID for edits
//       final pillId = widget.pill?.id ?? _generateSafeId();
//       print("Using pill ID: $pillId");
//
//       final pill = PillModel(
//         id: pillId,
//         pillName: _pillNameController.text.trim(),
//         dosage: _dosageController.text.trim(),
//         time: scheduledTime,
//         types: _selectedTypeIndices
//             .map((i) => medicineTypes[i]["label"] as String)
//             .toList(),
//         interval: _interval,
//       );
//
//       print("Pill Model Prepared: ${pill.pillName}, ID: ${pill.id}, Time: $scheduledTime, Interval: $_interval");
//
//       // Cancel existing alarm if editing
//       if (widget.pill != null) {
//         print("Cancelling existing alarm with ID: ${widget.pill!.id}");
//         await AlarmService.cancelAlarm(widget.pill!.id);
//
//         // Small delay to ensure cancellation is processed
//         await Future.delayed(const Duration(milliseconds: 500));
//       }
//
//       // Schedule new alarm
//       await AlarmService.scheduleAlarm(
//         id: pill.id,
//         title: "Pill Reminder 💊",
//         body: "Time to take your medicine: ${pill.pillName}",
//         scheduledTime: scheduledTime,
//         interval: _interval,
//       );
//
//       print("Alarm scheduled successfully with ID: ${pill.id}");
//
//       _showSuccessSnackBar(widget.pill != null
//           ? 'Pill reminder updated successfully!'
//           : 'Pill reminder scheduled successfully!');
//
//       // Return to previous screen with the pill data
//       Navigator.pop(context, pill);
//
//     } catch (e) {
//       print("Error scheduling alarm: $e");
//
//       String errorMessage = 'Failed to schedule reminder';
//       if (e.toString().contains('Missing type parameter')) {
//         errorMessage = 'Notification system error. Please restart the app and try again.';
//       } else if (e.toString().contains('permission')) {
//         errorMessage = 'Please enable notification permissions in settings';
//       }
//
//       _showErrorSnackBar(errorMessage);
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// Cancel alarm with confirmation
//   Future<void> _cancelAlarm() async {
//     if (widget.pill == null) return;
//
//     final bool? confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Cancel Alarm'),
//         content: const Text('Are you sure you want to cancel this alarm?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('No'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed == true) {
//       try {
//         await AlarmService.cancelAlarm(widget.pill!.id);
//         _showSuccessSnackBar('Alarm cancelled successfully');
//       } catch (e) {
//         print("Error cancelling alarm: $e");
//         _showErrorSnackBar('Failed to cancel alarm');
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final primaryColor = Colors.orangeAccent;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.pill != null ? 'Edit Pill' : 'Add Pill'),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         actions: [
//           if (widget.pill != null)
//             IconButton(
//               icon: const Icon(Icons.alarm_off),
//               onPressed: _cancelAlarm,
//               tooltip: 'Cancel Alarm',
//             ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildLabel("Medicine Name *"),
//             _buildTextField(_pillNameController, "Enter medicine name"),
//
//             _buildLabel("Dosage"),
//             _buildTextField(_dosageController, "Enter dosage (e.g., 500mg)", isNumber: false),
//
//             _buildLabel("Medicine Type"),
//             const SizedBox(height: 10),
//             _buildMedicineTypeSelector(primaryColor),
//
//             _buildLabel("Dose Interval (hours) *"),
//             _buildIntervalSelector(primaryColor),
//
//             _buildLabel("Reminder Time *"),
//             const SizedBox(height: 6),
//             _buildTimeSelector(primaryColor),
//
//             const SizedBox(height: 30),
//             _buildSaveButton(primaryColor),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 18, bottom: 6),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 15,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
//     return TextField(
//       controller: controller,
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         hintText: hint,
//         contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: Colors.grey.shade300),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(color: Colors.orangeAccent, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.grey.shade50,
//       ),
//     );
//   }
//
//   Widget _buildMedicineTypeSelector(Color primaryColor) {
//     return Wrap(
//       spacing: 10,
//       runSpacing: 10,
//       children: List.generate(medicineTypes.length, (index) {
//         final selected = _selectedTypeIndices.contains(index);
//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               selected
//                   ? _selectedTypeIndices.remove(index)
//                   : _selectedTypeIndices.add(index);
//             });
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
//             decoration: BoxDecoration(
//               color: selected ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(
//                 color: selected ? primaryColor : Colors.transparent,
//                 width: 1.5,
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   medicineTypes[index]["icon"],
//                   size: 28,
//                   color: selected ? primaryColor : Colors.grey,
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   medicineTypes[index]["label"],
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: selected ? primaryColor : Colors.grey[700],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   Widget _buildIntervalSelector(Color primaryColor) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//           decoration: BoxDecoration(
//             border: Border.all(color: primaryColor),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: DropdownButton<int>(
//             value: _interval,
//             items: List.generate(
//               24,
//                   (index) => DropdownMenuItem(
//                 value: index + 1,
//                 child: Text('${index + 1}'),
//               ),
//             ),
//             onChanged: (value) => setState(() => _interval = value ?? 8),
//             underline: const SizedBox(),
//             style: const TextStyle(fontSize: 16, color: Colors.black),
//           ),
//         ),
//         const SizedBox(width: 8),
//         const Text("hours", style: TextStyle(fontWeight: FontWeight.w600)),
//       ],
//     );
//   }
//
//   Widget _buildTimeSelector(Color primaryColor) {
//     return Center(
//       child: ElevatedButton.icon(
//         onPressed: _pickTime,
//         icon: const Icon(Icons.alarm, color: Colors.black),
//         label: Text(
//           _selectedTime == null
//               ? "Select Time"
//               : _selectedTime!.format(context),
//           style: const TextStyle(fontSize: 16),
//         ),
//         style: ElevatedButton.styleFrom(
//           foregroundColor: Colors.black,
//           backgroundColor: primaryColor,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSaveButton(Color primaryColor) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: (){
//           if(_selectedTime != null){
//             setDeviceAlarm(hour: _selectedTime?.hour ?? 0, minutes: _selectedTime?.minute ?? 0, msg: "Pill Reminder");
//           }else{
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text("Please select time"),
//                 backgroundColor: Colors.red,
//                 duration: const Duration(seconds: 3),
//               ),
//             );
//
//           }
//         },
//         // onPressed: _isLoading ? null : _saveReminder,
//         style: ElevatedButton.styleFrom(
//           foregroundColor: Colors.black,
//           backgroundColor: _isLoading ? Colors.grey : primaryColor,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//         ),
//         child: _isLoading
//             ? const SizedBox(
//           height: 20,
//           width: 20,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
//           ),
//         )
//             : Text(
//           widget.pill != null ? "Update Reminder" : "Save Reminder",
//           style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
//   void setDeviceAlarm({required int hour, required int minutes,required String msg}) {
//     if (Platform.isAndroid) {
//       final AndroidIntent intent = AndroidIntent(
//         action: 'android.intent.action.SET_ALARM',
//         arguments: <String, dynamic>{
//           'android.intent.extra.alarm.HOUR': hour,
//           'android.intent.extra.alarm.MINUTES': minutes,
//           'android.intent.extra.alarm.MESSAGE': msg,
//         },
//       );
//       intent.launch();
//     }
//   }
// }
//



import 'dart:io';
import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_time_meds/utils/alarm_service.dart';
import '../model/pill_model.dart';

class AddPillScreen extends StatefulWidget {
  const AddPillScreen({super.key});

  @override
  State<AddPillScreen> createState() => _AddPillScreenState();
}

class _AddPillScreenState extends State<AddPillScreen> {
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

  /// Generate a safe 32-bit integer ID with better collision avoidance
  int _generateSafeId() {
    final now = DateTime.now();

    // Create a more unique ID using microseconds and pill name
    final microTime = now.microsecondsSinceEpoch;
    final nameHash = _pillNameController.text.isNotEmpty
        ? _pillNameController.text.hashCode.abs()
        : 0;

    // Combine time and name hash, ensure it's positive and within 32-bit range
    final combinedId = (microTime + nameHash).abs();
    final safeId = combinedId % 2147483647;

    print("Generated safe ID: $safeId");
    return safeId;
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

  /// Save pill data to SharedPreferences
  Future<void> _savePillToPreferences(PillModel pill) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing pills
      final String? pillsJson = prefs.getString('pills');
      List<PillModel> pills = [];

      if (pillsJson != null) {
        final List<dynamic> pillsData = jsonDecode(pillsJson);
        pills = pillsData.map((data) => PillModel.fromJson(data)).toList();
      }

      // Add new pill
      pills.add(pill);

      // Save back to preferences
      final String updatedPillsJson = jsonEncode(pills.map((p) => p.toJson()).toList());
      await prefs.setString('pills', updatedPillsJson);

      print("Pill saved to SharedPreferences successfully");
    } catch (e) {
      print("Error saving pill to SharedPreferences: $e");
      throw e;
    }
  }

  /// Main save function that handles both alarm and data saving
  void _saveReminder() async {
    print("Save button tapped");

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

      // Generate a safe ID for new pill
      final pillId = _generateSafeId();
      print("Using pill ID: $pillId");

      final pill = PillModel(
        id: pillId,
        pillName: _pillNameController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: scheduledTime,
        types: _selectedTypeIndices
            .map((i) => medicineTypes[i]["label"] as String)
            .toList(),
        interval: _interval,
      );

      print("Pill Model Prepared: ${pill.pillName}, ID: ${pill.id}, Time: $scheduledTime, Interval: $_interval");

      // Save to SharedPreferences first
      await _savePillToPreferences(pill);

      // Set device alarm
      setDeviceAlarm(
          hour: _selectedTime!.hour,
          minutes: _selectedTime!.minute,
          msg: "Pill Reminder: ${pill.pillName}"
      );

      // Schedule new alarm
      await AlarmService.scheduleAlarm(
        id: pill.id,
        title: "Pill Reminder 💊",
        body: "Time to take your medicine: ${pill.pillName}",
        scheduledTime: scheduledTime,
        interval: _interval,
      );

      print("Alarm scheduled successfully with ID: ${pill.id}");

      _showSuccessSnackBar('Pill reminder added successfully!');

      // Return to previous screen with the pill data
      Navigator.pop(context, pill);

    } catch (e) {
      print("Error scheduling alarm: $e");

      String errorMessage = 'Failed to schedule reminder';
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orangeAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pill'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        elevation: 0,
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
            _buildSaveButton(primaryColor),
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
        const SizedBox(width: 8),
        const Text("hours", style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTimeSelector(Color primaryColor) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _pickTime,
        icon: const Icon(Icons.alarm, color: Colors.black),
        label: Text(
          _selectedTime == null
              ? "Select Time"
              : _selectedTime!.format(context),
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveReminder,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: _isLoading ? Colors.grey : primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        )
            : const Text(
          "Add Reminder",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

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
}