class Payment {
  final String id;
  final String customerId;
  final String? transactionId;
  final double jumlah;
  final DateTime tanggal;
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.customerId,
    this.transactionId,
    required this.jumlah,
    required this.tanggal,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      transactionId: json['transaction_id'] as String?,
      jumlah: (json['jumlah'] as num).toDouble(),
      tanggal: DateTime.parse(json['tanggal'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'transaction_id': transactionId,
      'jumlah': jumlah,
      'tanggal': tanggal.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? customerId,
    String? transactionId,
    double? jumlah,
    DateTime? tanggal,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      transactionId: transactionId ?? this.transactionId,
      jumlah: jumlah ?? this.jumlah,
      tanggal: tanggal ?? this.tanggal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
