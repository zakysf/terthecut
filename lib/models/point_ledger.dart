import '../config/date_format_helper.dart';

class PointLedgerEntry {
  final String id;
  final String customerId;
  final int delta; // Positif (tambah) atau Negatif (kurang/tukar)
  final String reason; // 'visit', 'redeem', 'adjustment'
  final String? refId;
  final String? note; // Nama layanan atau nama reward
  final DateTime createdAt;

  PointLedgerEntry({
    required this.id,
    required this.customerId,
    required this.delta,
    required this.reason,
    this.refId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPositive => delta > 0;

  String get formattedDelta => isPositive ? '+$delta Pts' : '$delta Pts';

  String get formattedDate => IndonesianDateHelper.formatShort(createdAt);

  String get reasonLabel {
    switch (reason) {
      case 'visit':
        return 'Kunjungan Layanan Barbershop';
      case 'redeem':
        return 'Penukaran Voucher Reward';
      case 'adjustment':
        return 'Penyesuaian Sistem';
      default:
        return reason;
    }
  }

  factory PointLedgerEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return PointLedgerEntry(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? 'visit',
      refId: json['ref_id']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'delta': delta,
      'reason': reason,
      'ref_id': refId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

