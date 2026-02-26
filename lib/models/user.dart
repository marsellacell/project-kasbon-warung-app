class User {
  final String id;
  final String? email;
  final String? nama;
  final String? role; // 'owner' or 'cashier'
  final DateTime? createdAt;

  User({required this.id, this.email, this.nama, this.role, this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      nama: json['nama'] as String?,
      role: json['role'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nama': nama,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isCashier => role == 'cashier';
}
