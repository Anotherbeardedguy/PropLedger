class Expense {
  final String id;
  final String propertyId;
  final String? unitId;
  final String? tenantId;
  final String category;
  final double amount;
  final DateTime date;
  final bool recurring;
  final String? notes;
  final String? receiptFile;
  final bool deductedFromDeposit;
  final DateTime created;
  final DateTime updated;

  Expense({
    required this.id,
    required this.propertyId,
    this.unitId,
    this.tenantId,
    required this.category,
    required this.amount,
    required this.date,
    this.recurring = false,
    this.notes,
    this.receiptFile,
    this.deductedFromDeposit = false,
    required this.created,
    required this.updated,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      unitId: json['unit_id'] as String?,
      tenantId: json['tenant_id'] as String?,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      recurring: json['recurring'] as bool? ?? false,
      notes: json['notes'] as String?,
      receiptFile: json['receipt_file'] as String?,
      deductedFromDeposit: json['deducted_from_deposit'] as bool? ?? false,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'tenant_id': tenantId,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'recurring': recurring,
      'notes': notes,
      'receipt_file': receiptFile,
      'deducted_from_deposit': deductedFromDeposit,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    String? tenantId,
    String? category,
    double? amount,
    DateTime? date,
    bool? recurring,
    String? notes,
    String? receiptFile,
    bool? deductedFromDeposit,
    DateTime? created,
    DateTime? updated,
  }) {
    return Expense(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      recurring: recurring ?? this.recurring,
      notes: notes ?? this.notes,
      receiptFile: receiptFile ?? this.receiptFile,
      deductedFromDeposit: deductedFromDeposit ?? this.deductedFromDeposit,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
