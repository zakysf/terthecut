import 'package:flutter/material.dart';
import '../config/date_format_helper.dart';
import '../config/theme.dart';

/// Model Notifikasi In-App (US-21)
class InAppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'booking', 'points', 'reward', 'general'
  final DateTime createdAt;
  bool isRead;

  InAppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  String get formattedDate => IndonesianDateHelper.formatShort(createdAt);

  IconData get iconData {
    switch (type) {
      case 'booking':
        return Icons.calendar_month_outlined;
      case 'points':
        return Icons.stars_outlined;
      case 'reward':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'booking':
        return AppColors.ink;
      case 'points':
        return AppColors.gold;
      case 'reward':
        return AppColors.accent;
      default:
        return AppColors.inkSoft;
    }
  }

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['customer_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': userId,
      'title': title,
      'message': message,
      'body': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
