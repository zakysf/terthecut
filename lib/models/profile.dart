class Profile {
  final String id;
  final String role; // 'customer' or 'admin'
  final String? phone;
  final String? name;
  final int pointsBalance;
  final int lifetimePoints;
  final DateTime? lastVisitAt;

  Profile({
    required this.id,
    required this.role,
    this.phone,
    this.name,
    this.pointsBalance = 0,
    this.lifetimePoints = 0,
    this.lastVisitAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      role: json['role'] ?? 'customer',
      phone: json['phone'],
      name: json['name'] ?? 'Pelanggan',
      pointsBalance: json['points_balance'] ?? 0,
      lifetimePoints: json['lifetime_points'] ?? 0,
      lastVisitAt: json['last_visit_at'] != null
          ? DateTime.tryParse(json['last_visit_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'phone': phone,
      'name': name,
      'points_balance': pointsBalance,
      'lifetime_points': lifetimePoints,
      'last_visit_at': lastVisitAt?.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';

  String get tier {
    if (lifetimePoints >= 300) return 'Gold';
    if (lifetimePoints >= 100) return 'Silver';
    return 'Bronze';
  }

  Profile copyWith({
    String? id,
    String? role,
    String? phone,
    String? name,
    int? pointsBalance,
    int? lifetimePoints,
    DateTime? lastVisitAt,
  }) {
    return Profile(
      id: id ?? this.id,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
    );
  }
}

