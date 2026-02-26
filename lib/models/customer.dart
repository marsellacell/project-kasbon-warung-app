class Customer {
  final String id;
  final String? userId;
  final String nama;
  final String? hp;
  final String? alamat;
  final double limitKredit;
  final DateTime? createdAt;

  Customer({
    required this.id,
    this.userId,
    required this.nama,
    this.hp,
    this.alamat,
    this.limitKredit = 0,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      nama: json['nama'] as String,
      hp: json['hp'] as String?,
      alamat: json['alamat'] as String?,
      limitKredit: (json['limit_kredit'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nama': nama,
      'hp': hp,
      'alamat': alamat,
      'limit_kredit': limitKredit,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? userId,
    String? nama,
    String? hp,
    String? alamat,
    double? limitKredit,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      hp: hp ?? this.hp,
      alamat: alamat ?? this.alamat,
      limitKredit: limitKredit ?? this.limitKredit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
