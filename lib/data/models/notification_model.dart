class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}