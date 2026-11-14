import '../config/date_format_helper.dart';

class RewardRedemption {
  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String rewardId;
  final String rewardName;
  final String? rewardDescription;
  final int pointsSpent;
  final String voucherCode;
  final String status; // 'active', 'used', 'expired'
  final DateTime expiresAt;
  final DateTime createdAt;

  RewardRedemption({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.rewardId,
    required this.rewardName,
    this.rewardDescription,
    required this.pointsSpent,
    required this.voucherCode,
    this.status = 'active',
    required this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isUsable => status == 'active' && !isExpired;

  String get formattedExpiry => IndonesianDateHelper.formatShort(expiresAt);

  String get formattedCreated => IndonesianDateHelper.formatShort(createdAt);

  String get statusLabel {
    if (status == 'used') return 'Sudah Dipakai';
    if (isExpired || status == 'expired') return 'Kedaluwarsa';
    return 'Siap Digunakan';
  }

  factory RewardRedemption.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return RewardRedemption(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ??
          (json['profiles'] is Map ? json['profiles']['name']?.toString() : null),
      customerPhone: json['customer_phone']?.toString() ??
          (json['profiles'] is Map ? json['profiles']['phone']?.toString() : null),
      rewardId: json['reward_id']?.toString() ?? '',
      rewardName: json['reward_name']?.toString() ?? (json['rewards']?['name']?.toString() ?? 'Voucher Reward'),
      rewardDescription: json['reward_description']?.toString() ?? (json['rewards']?['description']?.toString()),
      pointsSpent: (json['points_spent'] as num?)?.toInt() ?? 50,
      voucherCode: json['voucher_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      expiresAt: parseDate(json['expires_at']),
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'reward_id': rewardId,
      'reward_name': rewardName,
      'reward_description': rewardDescription,
      'points_spent': pointsSpent,
      'voucher_code': voucherCode,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  RewardRedemption copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? rewardId,
    String? rewardName,
    String? rewardDescription,
    int? pointsSpent,
    String? voucherCode,
    String? status,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return RewardRedemption(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      rewardId: rewardId ?? this.rewardId,
      rewardName: rewardName ?? this.rewardName,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      pointsSpent: pointsSpent ?? this.pointsSpent,
      voucherCode: voucherCode ?? this.voucherCode,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

