import '../../data/models/loan.dart';

/// Loan Calculator Service
/// Handles loan payment calculations and amortization schedules
class LoanCalculatorService {
  /// Calculate monthly payment for a loan
  /// Uses the standard mortgage formula: M = P[r(1+r)^n]/[(1+r)^n-1]
  /// where M = monthly payment, P = principal, r = monthly interest rate, n = number of payments
  double calculateMonthlyPayment({
    required double principal,
    required double annualInterestRate,
    required PaymentFrequency paymentFrequency,
    required int totalMonths,
  }) {
    if (annualInterestRate == 0) {
      // No interest, simple division
      final paymentsPerYear = _getPaymentsPerYear(paymentFrequency);
      final totalPayments = (totalMonths / 12) * paymentsPerYear;
      return principal / totalPayments;
    }

    final periodicRate = _getPeriodicRate(annualInterestRate, paymentFrequency);
    final paymentsPerYear = _getPaymentsPerYear(paymentFrequency);
    final totalPayments = (totalMonths / 12) * paymentsPerYear;

    // Mortgage formula
    final numerator = periodicRate * pow(1 + periodicRate, totalPayments);
    final denominator = pow(1 + periodicRate, totalPayments) - 1;

    return principal * (numerator / denominator);
  }

  /// Calculate monthly payment from a Loan object
  double getMonthlyPaymentFromLoan(Loan loan) {
    if (loan.endDate == null) {
      // No end date, use a default 30-year term
      return calculateMonthlyPayment(
        principal: loan.currentBalance,
        annualInterestRate: loan.interestRate,
        paymentFrequency: loan.paymentFrequency,
        totalMonths: 360, // 30 years
      );
    }

    final remainingMonths = loan.endDate!.difference(DateTime.now()).inDays ~/ 30;
    if (remainingMonths <= 0) {
      return 0; // Loan is complete
    }

    return calculateMonthlyPayment(
      principal: loan.currentBalance,
      annualInterestRate: loan.interestRate,
      paymentFrequency: loan.paymentFrequency,
      totalMonths: remainingMonths,
    );
  }

  /// Calculate the interest portion of the next payment
  double calculateInterestPortion({
    required double currentBalance,
    required double annualInterestRate,
    required PaymentFrequency paymentFrequency,
  }) {
    final periodicRate = _getPeriodicRate(annualInterestRate, paymentFrequency);
    return currentBalance * periodicRate;
  }

  /// Calculate the principal portion of the next payment
  double calculatePrincipalPortion({
    required double monthlyPayment,
    required double interestPortion,
  }) {
    return monthlyPayment - interestPortion;
  }

  /// Get periodic interest rate based on payment frequency
  double _getPeriodicRate(double annualRate, PaymentFrequency frequency) {
    final rateDecimal = annualRate / 100;
    switch (frequency) {
      case PaymentFrequency.monthly:
        return rateDecimal / 12;
      case PaymentFrequency.quarterly:
        return rateDecimal / 4;
      case PaymentFrequency.annually:
        return rateDecimal;
    }
  }

  /// Get number of payments per year based on frequency
  double _getPaymentsPerYear(PaymentFrequency frequency) {
    switch (frequency) {
      case PaymentFrequency.monthly:
        return 12;
      case PaymentFrequency.quarterly:
        return 4;
      case PaymentFrequency.annually:
        return 1;
    }
  }

  /// Power function helper
  double pow(double base, double exponent) {
    if (exponent == 0) return 1;
    if (exponent == 1) return base;
    
    double result = 1;
    final absExponent = exponent.abs().toInt();
    for (int i = 0; i < absExponent; i++) {
      result *= base;
    }
    
    return exponent < 0 ? 1 / result : result;
  }

  /// Convert payment to monthly equivalent
  /// e.g., quarterly payment of 3000 = 1000/month
  double convertToMonthlyPayment({
    required double paymentAmount,
    required PaymentFrequency frequency,
  }) {
    switch (frequency) {
      case PaymentFrequency.monthly:
        return paymentAmount;
      case PaymentFrequency.quarterly:
        return paymentAmount / 3;
      case PaymentFrequency.annually:
        return paymentAmount / 12;
    }
  }
}
