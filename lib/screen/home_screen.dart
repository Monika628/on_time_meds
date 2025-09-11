import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:on_time_meds/auth/login_screen.dart';
import 'package:on_time_meds/model/pill_model.dart';
import 'package:on_time_meds/screen/forgot_password_screen.dart';
import 'package:on_time_meds/screen/notification_screen.dart';
import 'package:on_time_meds/screen/pill_detail_screen.dart';
import 'package:on_time_meds/screen/update_pill_screen.dart';
import 'package:on_time_meds/utils/alarm_dialog_screen.dart';
import 'package:on_time_meds/utils/alarm_service.dart';
import 'package:on_time_meds/utils/storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_pill_screen.dart';

class HomeScreen extends StatefulWidget {
  final PillModel? pill;
  final String? userName;
  final String? userEmail;

  const HomeScreen({
    super.key,
    this.pill,
    this.userName,
    this.userEmail,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

int _notificationCount = 0; // Replace this with dynamic value in future

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<PillModel> pills = [];
  String userName = "User Name"; // Replace with actual user name
  String userEmail = "user@example.com"; // Replace with actual user email

  @override
   void initState() {
   super.initState();
  WidgetsBinding.instance.addObserver(this);
   AlarmService.initialize();

  // Initialize user data
  userName = widget.userName ?? "User Name";
   userEmail = widget.userEmail ?? "user@example.com";

 loadPills();
  _checkForActiveAlarms();
 }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForActiveAlarms();
    }
  }

  void _checkForActiveAlarms() {
    if (AlarmService.isAlarmPlaying) {
      final now = DateTime.now();
      for (final pill in pills) {
        final pillTime = DateTime(
          now.year,
          now.month,
          now.day,
          pill.time.hour,
          pill.time.minute,
        );

        if (now.difference(pillTime).inMinutes.abs() <= 1) {
          _showAlarmDialog(pill);
          break;
        }
      }
    }
  }

  void _showAlarmDialog(PillModel pill) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlarmDialogScreen(
        pill: pill,
        onAlarmStopped: () {
          _updatePillStatus(pill);
        },
      ),
    );
  }

  void _updatePillStatus(PillModel pill) {
    setState(() {
      // Update UI if needed
    });
  }

  void _showUserMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200, // Position from right side
        kToolbarHeight + 10, // Below app bar
        20,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      items: [
        // User Info Header
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.deepOrange[100],
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Divider
        const PopupMenuItem<String>(
          enabled: false,
          child: Divider(height: 1),
        ),

        // Forgot Password Option
        const PopupMenuItem<String>(
          enabled: false,
          child: Divider(height: 1, color: Color(0xFFECF0F1)),
        ),

// Forgot Password Option
        PopupMenuItem<String>(
          value: 'forgot_password',
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: const Color(0xFF7F8C8D),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Forgot Password',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Logout Option
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'forgot_password':
            _showForgotPasswordDialog();
            break;
          case 'logout':
            _showLogoutDialog();
            break;
        }
      }
    });
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showForgotPasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Dialog close
              logout(context); // Directly call logout method
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }


  void _performLogout() {
    // Implement logout logic here
    _showSnackBar('Logged out successfully');
    // Navigate to login screen
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildGoogleAdBanner() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Text(
          'Google Ad Space\n(320x50 Banner)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<PillModel> _sortPillsByTime(List<PillModel> pillList) {
    final now = DateTime.now();

    List<Map<String, dynamic>> pillsWithInfo = pillList.map((pill) {
      DateTime nextAlarm = DateTime(
        now.year,
        now.month,
        now.day,
        pill.time.hour,
        pill.time.minute,
      );

      bool isToday = !nextAlarm.isBefore(now);
      if (!isToday) {
        nextAlarm = nextAlarm.add(const Duration(days: 1));
      }

      int minutesUntilAlarm = nextAlarm.difference(now).inMinutes;

      return {
        'pill': pill,
        'nextAlarm': nextAlarm,
        'minutesUntilAlarm': minutesUntilAlarm,
        'isToday': isToday,
      };
    }).toList();

    pillsWithInfo.sort((a, b) => a['minutesUntilAlarm'].compareTo(b['minutesUntilAlarm']));

    return pillsWithInfo.map((info) => info['pill'] as PillModel).toList();
  }

  Future<void> loadPills() async {
    final storedPills = await Storage.getPills();
    setState(() {
      pills = _sortPillsByTime(storedPills);
    });
  }

  void addNewPill(PillModel newPill) async {
    await Storage.addPill(newPill);
    loadPills();
  }

  void updatePill(int index, PillModel updatedPill) async {
    await Storage.updatePill(updatedPill);
    loadPills();
  }

  void deletePill(int index) async {
    await Storage.deletePill(pills[index].id);
    loadPills();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case "Bottle":
        return Icons.local_pharmacy;
      case "Pill":
        return Icons.medication;
      case "Syringe":
        return Icons.vaccines;
      case "Tablet":
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  String _getNextAlarmTime(PillModel pill) {
    final now = DateTime.now();
    DateTime nextAlarm = DateTime(
      now.year,
      now.month,
      now.day,
      pill.time.hour,
      pill.time.minute,
    );

    bool isToday = !nextAlarm.isBefore(now);
    if (!isToday) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    final difference = nextAlarm.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (isToday) {
      if (hours > 0) {
        return 'Next: ${hours}h ${minutes}m';
      } else {
        return 'Next: ${minutes}m';
      }
    } else {
      return 'Tomorrow: ${pill.time.hour.toString().padLeft(2, '0')}:${pill.time.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getStatusColor(PillModel pill) {
    final now = DateTime.now();
    DateTime nextAlarm = DateTime(
      now.year,
      now.month,
      now.day,
      pill.time.hour,
      pill.time.minute,
    );

    bool isToday = !nextAlarm.isBefore(now);
    if (isToday) {
      final minutesUntilAlarm = nextAlarm.difference(now).inMinutes;
      if (minutesUntilAlarm <= 30) {
        return Colors.orange;
      } else {
        return Colors.green;
      }
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CircleAvatar(
          backgroundImage: AssetImage('assets/images/pill-reminder-icon.png'),
          radius: 26,
          backgroundColor: Colors.transparent,
        ),
        centerTitle: true,
        actions: [
          // User Profile Button with Side Dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'forgot_password':
                  _showForgotPasswordDialog();
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            offset: const Offset(0, 50),
            itemBuilder: (BuildContext context) => [
              // User Info Header
              PopupMenuItem<String>(
                enabled: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  width: 180,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.deepOrange[100],
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              const PopupMenuItem<String>(
                enabled: false,
                child: Divider(height: 1),
              ),

              // Forgot Password Option
              PopupMenuItem<String>(
                value: 'forgot_password',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Logout Option
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepOrange[100],
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGoogleAdBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: pills.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Worry less.\nLive healthier.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Welcome to Daily Dose.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'No Medicine',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        Text(
                          'Worry less.\nLive healthier.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Welcome to Daily Dose.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Google Ad Banner in middle of list
                  if (pills.length > 2) _buildGoogleAdBanner(),

                  ...pills.map((pill) {
                    int index = pills.indexOf(pill);
                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PillDetailScreen(pill: pill),
                          ),
                        );

                        if (result != null && result is int) {
                          setState(() {
                            pills.removeWhere((p) => p.id == result);
                          });
                          await Storage.deletePill(result);
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(pill),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pill.pillName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Time: ${pill.time.hour.toString().padLeft(2, '0')}:${pill.time.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                          if (pill.interval != null)
                                            Text(
                                              'Every ${pill.interval} hours',
                                              style: TextStyle(
                                                color: Colors.blue.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.black),
                                          onPressed: () async {
                                            final updated = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => UpdatePillScreen(pill: pill),
                                              ),
                                            );
                                            if (updated != null && updated is PillModel) {
                                              updatePill(index, updated);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Pill'),
                                                content: Text(
                                                  'Are you sure you want to delete ${pill.pillName}? This will also cancel its alarm.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              deletePill(index);
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(pill).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getStatusColor(pill).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getNextAlarmTime(pill),
                                    style: TextStyle(
                                      color: _getStatusColor(pill),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                if (pill.types != null)
                                  Wrap(
                                    spacing: 8,
                                    children: pill.types!.map((type) {
                                      return Chip(
                                        avatar: Icon(
                                          _getIconForType(type),
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                        label: Text(type),
                                        backgroundColor: Colors.deepOrange.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  // Google Ad Banner at bottom
                  _buildGoogleAdBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPillScreen()),
          );

          if (result != null && result is PillModel) {
            addNewPill(result);
          }
        },
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Add Pill", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.orangeAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}