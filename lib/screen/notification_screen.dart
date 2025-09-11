import 'package:flutter/material.dart';
import 'package:on_time_meds/model/notification_model.dart';
import 'package:on_time_meds/provider/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Debug: Print notification count when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      print('NotificationScreen opened with ${provider.notifications.length} notifications');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        // Debug: Print current notification count
        print('Building NotificationScreen with ${notificationProvider.notifications.length} notifications');

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.orangeAccent,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white), // optional if using custom leading
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Notifications (${notificationProvider.notifications.length})',
            ),
            actions: [
              if (notificationProvider.notifications.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'mark_all_read':
                        notificationProvider.markAllAsRead();
                        break;
                      case 'clear_all':
                        _showClearAllDialog(context, notificationProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Text('Mark All as Read'),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear All'),
                    ),
                  ],
                ),
            ],
          ),

          backgroundColor: Colors.grey[100],
          body: notificationProvider.notifications.isEmpty
              ? _buildEmptyState()
              : Column(
            children: [
              // Debug info container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Debug: ${notificationProvider.notifications.length} notifications found',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: notificationProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationProvider.notifications[index];
                    return _buildNotificationCard(
                      context,
                      notification,
                      index,
                      notificationProvider,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 30,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          // Text(
          //   'You\'ll see notifications here when you receive them',
          //   style: TextStyle(
          //     fontSize: 1,
          //     color: Colors.grey,
          //   ),
          //   textAlign: TextAlign.center,
          // ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context,
      NotificationModel notification,
      int index,
      NotificationProvider provider,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead ? Colors.grey.shade300 : Colors.blue.shade200,
          width: notification.isRead ? 0.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(index);
          }
          _handleNotificationTap(context, notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (!notification.isRead) const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            color: notification.isRead
                                ? Colors.grey.shade700
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_read':
                          provider.markAsRead(index);
                          break;
                        case 'delete':
                          provider.removeNotification(index);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Text('Mark as Read'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                  color: notification.isRead
                      ? Colors.grey.shade600
                      : Colors.grey.shade800,
                  height: 1.4,
                ),
              ),

              if (notification.data.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Info:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...notification.data.entries.map(
                            (entry) => Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    if (notification.data.containsKey('type')) {
      final type = notification.data['type'];
      switch (type) {
        case 'medicine':
          Navigator.pushNamed(context, '/medicine', arguments: notification.data);
          break;
        case 'reminder':
          Navigator.pushNamed(context, '/reminder', arguments: notification.data);
          break;
        default:
          break;
      }
    }
  }

  void _showClearAllDialog(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}