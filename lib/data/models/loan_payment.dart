class LoanPayment {
  final String id;
  final String loanId;
  final DateTime paymentDate;
  final double totalAmount;
  final double principalAmount;
  final double interestAmount;
  final double remainingBalance;
  final DateTime created;
  final DateTime updated;

  LoanPayment({
    required this.id,
    required this.loanId,
    required this.paymentDate,
    required this.totalAmount,
    required this.principalAmount,
    required this.interestAmount,
    required this.remainingBalance,
    required this.created,
    required this.updated,
  });

  factory LoanPayment.fromJson(Map<String, dynamic> json) {
    return LoanPayment(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      principalAmount: (json['principal_amount'] as num).toDouble(),
      interestAmount: (json['interest_amount'] as num).toDouble(),
      remainingBalance: (json['remaining_balance'] as num).toDouble(),
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'payment_date': paymentDate.toIso8601String(),
      'total_amount': totalAmount,
      'principal_amount': principalAmount,
      'interest_amount': interestAmount,
      'remaining_balance': remainingBalance,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  LoanPayment copyWith({
    String? id,
    String? loanId,
    DateTime? paymentDate,
    double? totalAmount,
    double? principalAmount,
    double? interestAmount,
    double? remainingBalance,
    DateTime? created,
    DateTime? updated,
  }) {
    return LoanPayment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      paymentDate: paymentDate ?? this.paymentDate,
      totalAmount: totalAmount ?? this.totalAmount,
      principalAmount: principalAmount ?? this.principalAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
