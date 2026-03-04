// lib/data/models/announcement_model.dart

class Announcement {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool isActive;
  final DateTime? publishedAt;
  final DateTime? expiredAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.isActive,
    this.publishedAt,
    this.expiredAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] == 1 || json['is_active'] == true, // Handle bool/int
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      expiredAt: json['expired_at'] != null ? DateTime.parse(json['expired_at']) : null,
    );
  }
}