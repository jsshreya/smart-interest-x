class Payment {
  final int? id;
  final int transactionId;
  final double amount;
  final DateTime paymentDate;
  final String mode;
  final String? proofPath;
  final String? note;
  final DateTime createdAt;

  Payment({
    this.id,
    required this.transactionId,
    required this.amount,
    required this.paymentDate,
    required this.mode,
    this.proofPath,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'mode': mode,
      'proofPath': proofPath,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      transactionId: map['transactionId'],
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate']),
      mode: map['mode'],
      proofPath: map['proofPath'],
      note: map['note'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Payment copyWith({
    int? id,
    int? transactionId,
    double? amount,
    DateTime? paymentDate,
    String? mode,
    String? proofPath,
    String? note,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      mode: mode ?? this.mode,
      proofPath: proofPath ?? this.proofPath,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
