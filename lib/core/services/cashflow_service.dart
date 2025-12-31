import '../../data/models/loan.dart';
import '../../data/models/rent_payment.dart';
import '../../data/models/expense.dart';
import '../../data/models/maintenance_task.dart';
import '../../data/models/unit.dart';
import 'loan_calculator_service.dart';

/// Cashflow Item
/// Represents a single cashflow entry with categorization
class CashflowItem {
  final String id;
  final String category; // 'rent', 'loan', 'upkeep', 'expense', 'maintenance'
  final String description;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String? relatedEntityId;

  CashflowItem({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.relatedEntityId,
  });
}

/// Monthly Cashflow Summary
class MonthlyCashflowSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netCashflow;
  
  final double rentIncome;
  final double loanPayments;
  final double upkeepCosts;
  final double maintenanceCosts;
  final double otherExpenses;

  final List<CashflowItem> items;

  MonthlyCashflowSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashflow,
    required this.rentIncome,
    required this.loanPayments,
    required this.upkeepCosts,
    required this.maintenanceCosts,
    required this.otherExpenses,
    required this.items,
  });
}

/// Cashflow Service
/// Aggregates all cashflow sources for comprehensive financial analysis
class CashflowService {
  final LoanCalculatorService _loanCalculator = LoanCalculatorService();

  /// Calculate monthly cashflow summary
  MonthlyCashflowSummary calculateMonthlyCashflow({
    required List<RentPayment> rentPayments,
    required List<Loan> loans,
    required List<Unit> units,
    required List<Expense> expenses,
    required List<MaintenanceTask> maintenanceTasks,
    DateTime? forMonth,
  }) {
    final targetMonth = forMonth ?? DateTime.now();
    final items = <CashflowItem>[];

    double rentIncome = 0;
    double loanPayments = 0;
    double upkeepCosts = 0;
    double maintenanceCosts = 0;
    double otherExpenses = 0;

    // 1. Rent Income
    for (final payment in rentPayments) {
      if (_isInMonth(payment.dueDate, targetMonth) && payment.status == PaymentStatus.paid) {
        rentIncome += payment.amount;
        items.add(CashflowItem(
          id: 'rent_${payment.id}',
          category: 'rent',
          description: 'Rent payment',
          amount: payment.amount,
          isIncome: true,
          date: payment.paidDate ?? payment.dueDate,
          relatedEntityId: payment.unitId,
        ));
      }
    }

    // 2. Loan Payments
    for (final loan in loans) {
      final monthlyPayment = _loanCalculator.getMonthlyPaymentFromLoan(loan);
      if (monthlyPayment > 0) {
        loanPayments += monthlyPayment;
        items.add(CashflowItem(
          id: 'loan_${loan.id}',
          category: 'loan',
          description: '${loan.lender} - ${loan.loanType ?? "Loan"}',
          amount: monthlyPayment,
          isIncome: false,
          date: targetMonth,
          relatedEntityId: loan.id,
        ));
      }
    }

    // 3. Unit Upkeep Costs
    for (final unit in units) {
      if (unit.upkeepAmount != null && unit.upkeepAmount! > 0) {
        upkeepCosts += unit.upkeepAmount!;
        items.add(CashflowItem(
          id: 'upkeep_${unit.id}',
          category: 'upkeep',
          description: '${unit.unitName} - Upkeep',
          amount: unit.upkeepAmount!,
          isIncome: false,
          date: targetMonth,
          relatedEntityId: unit.id,
        ));
      }
    }

    // 4. Maintenance Task Costs
    for (final task in maintenanceTasks) {
      if (task.cost != null && 
          task.cost! > 0 && 
          task.status == TaskStatus.done &&
          _isInMonth(task.updated, targetMonth)) {
        maintenanceCosts += task.cost!;
        items.add(CashflowItem(
          id: 'maintenance_${task.id}',
          category: 'maintenance',
          description: task.description,
          amount: task.cost!,
          isIncome: false,
          date: task.updated,
          relatedEntityId: task.id,
        ));
      }
    }

    // 5. Other Expenses
    for (final expense in expenses) {
      if (_isInMonth(expense.date, targetMonth)) {
        otherExpenses += expense.amount;
        items.add(CashflowItem(
          id: 'expense_${expense.id}',
          category: 'expense',
          description: '${expense.category} - ${expense.notes ?? ""}',
          amount: expense.amount,
          isIncome: false,
          date: expense.date,
          relatedEntityId: expense.id,
        ));
      }
    }

    final totalIncome = rentIncome;
    final totalExpenses = loanPayments + upkeepCosts + maintenanceCosts + otherExpenses;
    final netCashflow = totalIncome - totalExpenses;

    return MonthlyCashflowSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netCashflow: netCashflow,
      rentIncome: rentIncome,
      loanPayments: loanPayments,
      upkeepCosts: upkeepCosts,
      maintenanceCosts: maintenanceCosts,
      otherExpenses: otherExpenses,
      items: items,
    );
  }

  /// Check if a date falls within the target month
  bool _isInMonth(DateTime date, DateTime targetMonth) {
    return date.year == targetMonth.year && date.month == targetMonth.month;
  }

  /// Calculate annual cashflow projection
  List<MonthlyCashflowSummary> calculateAnnualProjection({
    required List<RentPayment> rentPayments,
    required List<Loan> loans,
    required List<Unit> units,
    required List<Expense> expenses,
    required List<MaintenanceTask> maintenanceTasks,
    DateTime? startMonth,
  }) {
    final start = startMonth ?? DateTime.now();
    final projections = <MonthlyCashflowSummary>[];

    for (int i = 0; i < 12; i++) {
      final month = DateTime(start.year, start.month + i, 1);
      final summary = calculateMonthlyCashflow(
        rentPayments: rentPayments,
        loans: loans,
        units: units,
        expenses: expenses,
        maintenanceTasks: maintenanceTasks,
        forMonth: month,
      );
      projections.add(summary);
    }

    return projections;
  }
}
