class Reward {
  final String id;
  final String name;
  final String? description;
  final String? terms;
  final int pointsCost;
  final String? photoUrl;
  final bool isActive;
  final int sortOrder;

  Reward({
    required this.id,
    required this.name,
    this.description,
    this.terms,
    required this.pointsCost,
    this.photoUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      terms: json['terms']?.toString(),
      pointsCost: (json['points_cost'] as num?)?.toInt() ?? 50,
      photoUrl: json['photo_url']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == null,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'terms': terms,
      'points_cost': pointsCost,
      'photo_url': photoUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

