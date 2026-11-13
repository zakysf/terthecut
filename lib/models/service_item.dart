class ServiceCategory {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final int sortOrder;

  ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.sortOrder = 0,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      photoUrl: json['photo_url'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photo_url': photoUrl,
      'sort_order': sortOrder,
    };
  }
}

class ServiceItem {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final int price;
  final int durationHours; // Bulat 1, 2, atau 3 jam (tanpa menit)
  final int slotsNeeded;
  final String? audience; // 'Pria', 'Wanita', atau null (unisex)
  final int points;
  final String? photoUrl;
  final bool isActive;
  final int sortOrder;

  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.durationHours,
    int? slotsNeeded,
    this.audience,
    this.points = 10,
    this.photoUrl,
    this.isActive = true,
    this.sortOrder = 0,
  }) : slotsNeeded = slotsNeeded ?? durationHours;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final durHours = json['duration_hours'] ?? 1;
    return ServiceItem(
      id: json['id'] ?? '',
      categoryId: json['category_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price'] ?? 0,
      durationHours: durHours,
      slotsNeeded: json['slots_needed'] ?? durHours,
      audience: json['audience'],
      points: json['points'] ?? 10,
      photoUrl: json['photo_url'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'duration_hours': durationHours,
      'slots_needed': slotsNeeded,
      'audience': audience,
      'points': points,
      'photo_url': photoUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

