enum PaymentStatus { paid, late, missing }

class RentPayment {
  final String id;
  final String unitId;
  final String tenantId;
  final DateTime dueDate;
  final DateTime? paidDate;
  final double amount;
  final PaymentStatus status;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  RentPayment({
    required this.id,
    required this.unitId,
    required this.tenantId,
    required this.dueDate,
    this.paidDate,
    required this.amount,
    required this.status,
    this.notes,
    required this.created,
    required this.updated,
  });

  factory RentPayment.fromJson(Map<String, dynamic> json) {
    return RentPayment(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      tenantId: json['tenant_id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      amount: (json['amount'] as num).toDouble(),
      status: _parseStatus(json['status'] as String),
      notes: json['notes'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'tenant_id': tenantId,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'amount': amount,
      'status': _statusToString(status),
      'notes': notes,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  static PaymentStatus _parseStatus(String status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'late':
        return PaymentStatus.late;
      case 'missing':
        return PaymentStatus.missing;
      default:
        return PaymentStatus.missing;
    }
  }

  static String _statusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.late:
        return 'late';
      case PaymentStatus.missing:
        return 'missing';
    }
  }

  int get daysOverdue {
    if (paidDate != null) return 0;
    final today = DateTime.now();
    if (today.isAfter(dueDate)) {
      return today.difference(dueDate).inDays;
    }
    return 0;
  }

  bool get isOverdue => daysOverdue > 0;

  RentPayment copyWith({
    String? id,
    String? unitId,
    String? tenantId,
    DateTime? dueDate,
    DateTime? paidDate,
    double? amount,
    PaymentStatus? status,
    String? notes,
    DateTime? created,
    DateTime? updated,
  }) {
    return RentPayment(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
