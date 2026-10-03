class LoanTransaction {
  final int? id;
  final int personId;
  final double amount;
  final String type;
  final double interestRate;
  final String interestPeriod;
  final DateTime startDate;
  final DateTime? dueDate;
  final String? note;
  final String status;
  final DateTime createdAt;

  LoanTransaction({
    this.id,
    required this.personId,
    required this.amount,
    required this.type,
    required this.interestRate,
    required this.interestPeriod,
    required this.startDate,
    this.dueDate,
    this.note,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personId': personId,
      'amount': amount,
      'type': type,
      'interestRate': interestRate,
      'interestPeriod': interestPeriod,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'note': note,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LoanTransaction.fromMap(Map<String, dynamic> map) {
    return LoanTransaction(
      id: map['id'],
      personId: map['personId'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      interestRate: (map['interestRate'] as num).toDouble(),
      interestPeriod: map['interestPeriod'],
      startDate: DateTime.parse(map['startDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      note: map['note'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  LoanTransaction copyWith({
    int? id,
    int? personId,
    double? amount,
    String? type,
    double? interestRate,
    String? interestPeriod,
    DateTime? startDate,
    DateTime? dueDate,
    String? note,
    String? status,
    DateTime? createdAt,
  }) {
    return LoanTransaction(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      interestRate: interestRate ?? this.interestRate,
      interestPeriod: interestPeriod ?? this.interestPeriod,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
