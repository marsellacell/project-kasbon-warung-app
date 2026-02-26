enum TransactionStatus { active, paid, overdue }

class Transaction {
  final String id;
  final String customerId;
  final String namaBarang;
  final double nominal;
  final String? deskripsi;
  final DateTime tanggal;
  final DateTime? tenggat;
  final TransactionStatus status;
  final DateTime? createdAt;

  Transaction({
    required this.id,
    required this.customerId,
    required this.namaBarang,
    required this.nominal,
    this.deskripsi,
    required this.tanggal,
    this.tenggat,
    this.status = TransactionStatus.active,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      namaBarang: json['nama_barang'] as String,
      nominal: (json['nominal'] as num).toDouble(),
      deskripsi: json['deskripsi'] as String?,
      tanggal: DateTime.parse(json['tanggal'] as String),
      tenggat: json['tenggat'] != null
          ? DateTime.parse(json['tenggat'] as String)
          : null,
      status: _parseStatus(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static TransactionStatus _parseStatus(String? status) {
    switch (status) {
      case 'paid':
        return TransactionStatus.paid;
      case 'overdue':
        return TransactionStatus.overdue;
      default:
        return TransactionStatus.active;
    }
  }

  String get statusString {
    switch (status) {
      case TransactionStatus.active:
        return 'active';
      case TransactionStatus.paid:
        return 'paid';
      case TransactionStatus.overdue:
        return 'overdue';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'nama_barang': namaBarang,
      'nominal': nominal,
      'deskripsi': deskripsi,
      'tanggal': tanggal.toIso8601String(),
      'tenggat': tenggat?.toIso8601String(),
      'status': statusString,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? customerId,
    String? namaBarang,
    double? nominal,
    String? deskripsi,
    DateTime? tanggal,
    DateTime? tenggat,
    TransactionStatus? status,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      namaBarang: namaBarang ?? this.namaBarang,
      nominal: nominal ?? this.nominal,
      deskripsi: deskripsi ?? this.deskripsi,
      tanggal: tanggal ?? this.tanggal,
      tenggat: tenggat ?? this.tenggat,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOverdue {
    if (tenggat == null || status == TransactionStatus.paid) return false;
    return DateTime.now().isAfter(tenggat!);
  }
}
