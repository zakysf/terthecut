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
  });

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
    );
  }

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
    };
  }
}

