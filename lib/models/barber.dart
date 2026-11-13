class Barber {
  final String id;
  final String branchId;
  final String name;
  final String? photoUrl;
  final bool isActive;
  final int sortOrder;

  Barber({
    required this.id,
    required this.branchId,
    required this.name,
    this.photoUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'] ?? '',
      branchId: json['branch_id'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photo_url'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'photo_url': photoUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}

