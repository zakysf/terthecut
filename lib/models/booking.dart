import '../config/date_format_helper.dart';

enum BarberPref { chosen, auto }

enum BookingStatus { confirmed, arrived, completed, cancelled }

class Booking {
  final String id;
  final String code;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final String barberId;
  final String barberName;
  final String barberPref; // 'chosen' or 'auto'
  final String serviceId;
  final String serviceName;
  final int servicePrice;
  final int servicePoints;
  final int durationHours; // Bulat 1, 2, atau 3 jam
  final String? hairstyleId;
  final String? hairstyleName;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status; // 'confirmed', 'arrived', 'completed', 'cancelled'
  final String? cancelReason;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.code,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
    required this.barberId,
    required this.barberName,
    this.barberPref = 'chosen',
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.servicePoints,
    required this.durationHours,
    this.hairstyleId,
    this.hairstyleName,
    required this.startsAt,
    required this.endsAt,
    this.status = 'confirmed',
    this.cancelReason,
    this.arrivedAt,
    this.completedAt,
    this.cancelledAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Kebijakan US-10: Pembatalan hanya diizinkan minimal 2 jam (120 menit) sebelum jadwal mulai
  bool get canCancel {
    if (status != 'confirmed') return false;
    final now = DateTime.now();
    final difference = startsAt.difference(now);
    return difference.inMinutes >= 120;
  }

  /// Menghitung sisa waktu hingga batas akhir pembatalan
  Duration get remainingTimeToCancel {
    final deadline = startsAt.subtract(const Duration(hours: 2));
    final now = DateTime.now();
    return deadline.difference(now);
  }

  /// Format tanggal ramah pengguna (contoh: "Sabtu, 14 Nov 2026")
  String get formattedDate {
    return IndonesianDateHelper.formatShort(startsAt);
  }

  /// Format rentang jam pengerjaan bulat (contoh: "14:00 - 16:00 WIB")
  String get formattedTimeRange {
    return IndonesianDateHelper.formatTimeRange(startsAt, endsAt);
  }

  /// Label status yang ramah tampilan
  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'arrived':
        return 'Pelanggan Hadir';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return Booking(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      branchId: json['branch_id']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? 'Cabang Ter The Cut',
      branchAddress: json['branch_address']?.toString() ?? '',
      barberId: json['barber_id']?.toString() ?? '',
      barberName: json['barber_name']?.toString() ?? 'Kapster Ter The Cut',
      barberPref: json['barber_pref']?.toString() ?? 'chosen',
      serviceId: json['service_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? 'Layanan Ter The Cut',
      servicePrice: (json['service_price'] as num?)?.toInt() ?? 0,
      servicePoints: (json['service_points'] as num?)?.toInt() ?? 10,
      durationHours: (json['duration_hours'] as num?)?.toInt() ?? 1,
      hairstyleId: json['hairstyle_id']?.toString(),
      hairstyleName: json['hairstyle_name']?.toString(),
      startsAt: parseDate(json['starts_at']),
      endsAt: parseDate(json['ends_at']),
      status: json['status']?.toString() ?? 'confirmed',
      cancelReason: json['cancel_reason']?.toString(),
      arrivedAt: json['arrived_at'] != null ? parseDate(json['arrived_at']) : null,
      completedAt: json['completed_at'] != null ? parseDate(json['completed_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? parseDate(json['cancelled_at']) : null,
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'customer_id': customerId,
      'branch_id': branchId,
      'barber_id': barberId,
      'barber_pref': barberPref,
      'service_id': serviceId,
      'hairstyle_id': hairstyleId,
      'service_name': serviceName,
      'service_price': servicePrice,
      'service_points': servicePoints,
      'duration_hours': durationHours,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'status': status,
      'cancel_reason': cancelReason,
      'arrived_at': arrivedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? code,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? branchId,
    String? branchName,
    String? branchAddress,
    String? barberId,
    String? barberName,
    String? barberPref,
    String? serviceId,
    String? serviceName,
    int? servicePrice,
    int? servicePoints,
    int? durationHours,
    String? hairstyleId,
    String? hairstyleName,
    DateTime? startsAt,
    DateTime? endsAt,
    String? status,
    String? cancelReason,
    DateTime? arrivedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      code: code ?? this.code,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchAddress: branchAddress ?? this.branchAddress,
      barberId: barberId ?? this.barberId,
      barberName: barberName ?? this.barberName,
      barberPref: barberPref ?? this.barberPref,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      servicePoints: servicePoints ?? this.servicePoints,
      durationHours: durationHours ?? this.durationHours,
      hairstyleId: hairstyleId ?? this.hairstyleId,
      hairstyleName: hairstyleName ?? this.hairstyleName,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

