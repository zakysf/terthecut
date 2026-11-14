import '../config/date_format_helper.dart';

/// Model Kritik & Saran Pelanggan (US-14, US-15)
class FeedbackItem {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String category; // Pelayanan, Kebersihan, Kapster, Aplikasi, Lainnya
  final String message;
  final int rating; // 1 - 5
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.category,
    required this.message,
    this.rating = 5,
    required this.createdAt,
  });

  String get formattedDate => IndonesianDateHelper.formatShort(createdAt);

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['customer_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Pelanggan',
      userPhone: json['user_phone'] as String? ?? '',
      category: json['category'] as String? ?? 'Pelayanan',
      message: json['message'] as String? ?? json['content'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'category': category,
      'message': message,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
