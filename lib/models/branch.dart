/// ============================================================================
/// Model Data Cabang (Branch Model)
/// ============================================================================
/// Merepresentasikan entitas cabang pangkas rambut Ter The Cut.
/// Menyimpan informasi identitas, alamat, jam operasional, serta koordinat LBS.
class Branch {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? photoUrl;
  final String openTime;
  final String closeTime;
  final bool isActive;
  final int sortOrder;

  // Koordinat geografis untuk Location-Based Services (LBS Modul 7)
  final double? latitude;
  final double? longitude;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.photoUrl,
    this.openTime = '10:00',
    this.closeTime = '22:00',
    this.isActive = true,
    this.sortOrder = 0,
    this.latitude,
    this.longitude,
  });

  /// Mengonversi format Map/JSON dari Supabase REST API menjadi objek Branch di Dart
  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? 'Yogyakarta',
      photoUrl: json['photo_url'],
      openTime: json['open_time'] ?? '10:00',
      closeTime: json['close_time'] ?? '22:00',
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      // Konversi tipe numeric database ke double secara aman
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  /// Mengonversi objek Branch menjadi JSON untuk dikirim ke database Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'photo_url': photoUrl,
      'open_time': openTime,
      'close_time': closeTime,
      'is_active': isActive,
      'sort_order': sortOrder,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Pola Immutability: Membuat salinan objek dengan modifikasi sebagian field
  Branch copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? photoUrl,
    String? openTime,
    String? closeTime,
    bool? isActive,
    int? sortOrder,
    double? latitude,
    double? longitude,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      photoUrl: photoUrl ?? this.photoUrl,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Format tampilan jam operasional (misal "10:00 - 22:00 WIB", membuang detik ":00")
  String get formattedOperatingHours {
    final o = openTime.length >= 5 ? openTime.substring(0, 5) : openTime;
    final c = closeTime.length >= 5 ? closeTime.substring(0, 5) : closeTime;
    return '$o - $c WIB';
  }

  /// Pengecekan real-time apakah cabang saat ini sedang buka
  bool get isOpenNow {
    if (!isActive) return false;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Parse jam buka (misal "10:00:00" atau "10:00")
    final openParts = openTime.split(':');
    final openHour = int.tryParse(openParts[0]) ?? 10;
    final openMin = openParts.length > 1 ? (int.tryParse(openParts[1]) ?? 0) : 0;
    final openTotal = openHour * 60 + openMin;

    // Parse jam tutup (misal "22:00:00" atau "22:00")
    final closeParts = closeTime.split(':');
    final closeHour = int.tryParse(closeParts[0]) ?? 22;
    final closeMin = closeParts.length > 1 ? (int.tryParse(closeParts[1]) ?? 0) : 0;
    final closeTotal = closeHour * 60 + closeMin;

    return currentMinutes >= openTotal && currentMinutes < closeTotal;
  }

  /// Teks status real-time
  String get statusText {
    if (!isActive) return 'TUTUP';
    return isOpenNow ? 'BUKA' : 'TUTUP';
  }
}
