import '../config/date_format_helper.dart';

/// Model Promo & Diskon Segmen (US-16, US-17)
class Promotion {
  final String id;
  final String title;
  final String description;
  final int discountPercent; // misal 15, 20, 30
  final String targetTier; // 'all', 'silver', 'gold', 'platinum'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercent,
    this.targetTier = 'all',
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  String get targetTierLabel {
    switch (targetTier.toLowerCase()) {
      case 'silver':
        return 'Khusus Silver';
      case 'gold':
        return 'Khusus Gold';
      case 'platinum':
        return 'Khusus Platinum';
      default:
        return 'Semua Member';
    }
  }

  String get formattedPeriod {
    final start = IndonesianDateHelper.formatShort(startDate);
    final end = IndonesianDateHelper.formatShort(endDate);
    return '$start - $end';
  }

  bool get isValidNow {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  bool isEligibleForTier(String? userTier) {
    if (targetTier.toLowerCase() == 'all') return true;
    if (userTier == null) return false;
    return targetTier.toLowerCase() == userTier.toLowerCase();
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      discountPercent: json['discount_percent'] as int? ?? 10,
      targetTier: json['target_tier'] as String? ?? 'all',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String) ??
              DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discount_percent': discountPercent,
      'target_tier': targetTier,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
    };
  }

  Promotion copyWith({
    String? id,
    String? title,
    String? description,
    int? discountPercent,
    String? targetTier,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Promotion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      targetTier: targetTier ?? this.targetTier,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
