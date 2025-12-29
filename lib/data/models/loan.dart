enum InterestType { fixed, variable }

enum PaymentFrequency { monthly, quarterly, annually }

class Loan {
  final String id;
  final String propertyId;
  final String lender;
  final String? loanType;
  final double originalAmount;
  final double currentBalance;
  final double interestRate;
  final InterestType interestType;
  final PaymentFrequency paymentFrequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  Loan({
    required this.id,
    required this.propertyId,
    required this.lender,
    this.loanType,
    required this.originalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.interestType,
    required this.paymentFrequency,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.created,
    required this.updated,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      lender: json['lender'] as String,
      loanType: json['loan_type'] as String?,
      originalAmount: (json['original_amount'] as num).toDouble(),
      currentBalance: (json['current_balance'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      interestType: _parseInterestType(json['interest_type'] as String),
      paymentFrequency:
          _parsePaymentFrequency(json['payment_frequency'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      notes: json['notes'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'lender': lender,
      'loan_type': loanType,
      'original_amount': originalAmount,
      'current_balance': currentBalance,
      'interest_rate': interestRate,
      'interest_type': _interestTypeToString(interestType),
      'payment_frequency': _paymentFrequencyToString(paymentFrequency),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  static InterestType _parseInterestType(String type) {
    return type == 'variable' ? InterestType.variable : InterestType.fixed;
  }

  static String _interestTypeToString(InterestType type) {
    return type == InterestType.variable ? 'variable' : 'fixed';
  }

  static PaymentFrequency _parsePaymentFrequency(String frequency) {
    switch (frequency) {
      case 'quarterly':
        return PaymentFrequency.quarterly;
      case 'annually':
        return PaymentFrequency.annually;
      case 'monthly':
      default:
        return PaymentFrequency.monthly;
    }
  }

  static String _paymentFrequencyToString(PaymentFrequency frequency) {
    switch (frequency) {
      case PaymentFrequency.quarterly:
        return 'quarterly';
      case PaymentFrequency.annually:
        return 'annually';
      case PaymentFrequency.monthly:
        return 'monthly';
    }
  }

  double get totalPaid => originalAmount - currentBalance;

  Loan copyWith({
    String? id,
    String? propertyId,
    String? lender,
    String? loanType,
    double? originalAmount,
    double? currentBalance,
    double? interestRate,
    InterestType? interestType,
    PaymentFrequency? paymentFrequency,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    DateTime? created,
    DateTime? updated,
  }) {
    return Loan(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      lender: lender ?? this.lender,
      loanType: loanType ?? this.loanType,
      originalAmount: originalAmount ?? this.originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
