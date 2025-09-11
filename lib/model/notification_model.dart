class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.data = const {},
    this.isRead = false,
  });

  factory NotificationModel.fromFirebase(Map<String, dynamic> data, String messageId) {
    return NotificationModel(
      id: messageId,
      title: data['title'] ?? 'No Title',
      body: data['body'] ?? 'No Body',
      timestamp: DateTime.now(),
      data: data,
      isRead: false,
    );
  }
}
