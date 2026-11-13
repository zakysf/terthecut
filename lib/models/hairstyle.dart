class Hairstyle {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final bool isActive;
  bool isFavorite;

  Hairstyle({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.isActive = true,
    this.isFavorite = false,
  });

  factory Hairstyle.fromJson(Map<String, dynamic> json) {
    return Hairstyle(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      photoUrl: json['photo_url'],
      isActive: json['is_active'] ?? true,
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photo_url': photoUrl,
      'is_active': isActive,
      'is_favorite': isFavorite,
    };
  }
}

