import '../../data/models/property.dart';
import '../../data/models/unit.dart';
import '../../data/models/rent_payment.dart';
import '../../data/models/expense.dart';
import '../../data/models/loan.dart';
import '../../data/models/tenant.dart';

class PropertyPerformanceMetrics {
  final String propertyId;
  final String propertyName;
  final int totalUnits;
  final int occupiedUnits;
  final double occupancyRate;
  final double monthlyRentCollected;
  final double monthlyExpenses;
  final double monthlyNOI;
  final double annualGrossRevenue;
  final double annualExpenses;
  final double annualNOI;
  final double propertyValue;
  final double totalDebt;
  final double equity;
  final double capRate;
  final double cashOnCashReturn;
  final double roi;
  final double revenuePerUnit;

  PropertyPerformanceMetrics({
    required this.propertyId,
    required this.propertyName,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.occupancyRate,
    required this.monthlyRentCollected,
    required this.monthlyExpenses,
    required this.monthlyNOI,
    required this.annualGrossRevenue,
    required this.annualExpenses,
    required this.annualNOI,
    required this.propertyValue,
    required this.totalDebt,
    required this.equity,
    required this.capRate,
    required this.cashOnCashReturn,
    required this.roi,
    required this.revenuePerUnit,
  });
}

class PropertyPerformanceService {
  PropertyPerformanceMetrics calculatePropertyPerformance({
    required Property property,
    required List<Unit> propertyUnits,
    required List<RentPayment> allPayments,
    required List<Expense> allExpenses,
    required List<Loan> allLoans,
    required List<Tenant> allTenants,
  }) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final oneYearAgo = now.subtract(const Duration(days: 365));

    // Unit metrics
    final totalUnits = propertyUnits.length;
    final occupiedUnits = propertyUnits.where((u) => u.status == UnitStatus.occupied).length;
    final occupancyRate = totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0.0;

    // Get property tenants
    final propertyUnitIds = propertyUnits.map((u) => u.id).toSet();
    final propertyTenants = allTenants.where((t) => propertyUnitIds.contains(t.unitId)).toList();
    final tenantIds = propertyTenants.map((t) => t.id).toSet();

    // Monthly rent collected (last 30 days, paid only)
    final monthlyRentCollected = allPayments
        .where((p) => 
            tenantIds.contains(p.tenantId) &&
            p.paidDate != null &&
            p.paidDate!.isAfter(thirtyDaysAgo))
        .fold<double>(0, (sum, p) => sum + p.amount);

    // Monthly expenses (last 30 days)
    final monthlyExpenses = allExpenses
        .where((e) =>
            e.propertyId == property.id &&
            e.date.isAfter(thirtyDaysAgo))
        .fold<double>(0, (sum, e) => sum + e.amount);

    // Monthly NOI
    final monthlyNOI = monthlyRentCollected - monthlyExpenses;

    // Annual metrics (last 12 months)
    final annualRentCollected = allPayments
        .where((p) =>
            tenantIds.contains(p.tenantId) &&
            p.paidDate != null &&
            p.paidDate!.isAfter(oneYearAgo))
        .fold<double>(0, (sum, p) => sum + p.amount);

    final annualExpenses = allExpenses
        .where((e) =>
            e.propertyId == property.id &&
            e.date.isAfter(oneYearAgo))
        .fold<double>(0, (sum, e) => sum + e.amount);

    final annualNOI = annualRentCollected - annualExpenses;

    // Property value and debt
    final propertyValue = property.estimatedValue ?? 0.0;
    final propertyLoans = allLoans.where((l) => l.propertyId == property.id).toList();
    final totalDebt = propertyLoans.fold<double>(0, (sum, l) => sum + l.currentBalance);
    final equity = propertyValue - totalDebt;

    // Cap Rate = Annual NOI / Property Value
    final capRate = propertyValue > 0 ? (annualNOI / propertyValue) * 100 : 0.0;

    // Cash-on-Cash Return = Annual Cash Flow / Total Cash Invested
    // Using equity as proxy for cash invested
    final cashOnCashReturn = equity > 0 ? (annualNOI / equity) * 100 : 0.0;

    // ROI = (Current Value - Purchase Price) / Purchase Price
    final purchasePrice = property.purchasePrice ?? propertyValue;
    final roi = purchasePrice > 0 ? ((propertyValue - purchasePrice) / purchasePrice) * 100 : 0.0;

    // Revenue per unit
    final revenuePerUnit = totalUnits > 0 ? monthlyRentCollected / totalUnits : 0.0;

    // Projected annual revenue based on current monthly (potential revenue if fully occupied)
    final potentialMonthlyRent = propertyUnits.fold<double>(0, (sum, u) => sum + u.rentAmount);
    final annualGrossRevenue = potentialMonthlyRent * 12;

    return PropertyPerformanceMetrics(
      propertyId: property.id,
      propertyName: property.name,
      totalUnits: totalUnits,
      occupiedUnits: occupiedUnits,
      occupancyRate: occupancyRate,
      monthlyRentCollected: monthlyRentCollected,
      monthlyExpenses: monthlyExpenses,
      monthlyNOI: monthlyNOI,
      annualGrossRevenue: annualGrossRevenue,
      annualExpenses: annualExpenses,
      annualNOI: annualNOI,
      propertyValue: propertyValue,
      totalDebt: totalDebt,
      equity: equity,
      capRate: capRate,
      cashOnCashReturn: cashOnCashReturn,
      roi: roi,
      revenuePerUnit: revenuePerUnit,
    );
  }

  List<PropertyPerformanceMetrics> calculateAllPropertiesPerformance({
    required List<Property> properties,
    required List<Unit> allUnits,
    required List<RentPayment> allPayments,
    required List<Expense> allExpenses,
    required List<Loan> allLoans,
    required List<Tenant> allTenants,
  }) {
    return properties.map((property) {
      final propertyUnits = allUnits.where((u) => u.propertyId == property.id).toList();
      return calculatePropertyPerformance(
        property: property,
        propertyUnits: propertyUnits,
        allPayments: allPayments,
        allExpenses: allExpenses,
        allLoans: allLoans,
        allTenants: allTenants,
      );
    }).toList();
  }

  // Portfolio-wide metrics
  Map<String, double> calculatePortfolioMetrics(List<PropertyPerformanceMetrics> propertyMetrics) {
    if (propertyMetrics.isEmpty) {
      return {
        'totalProperties': 0,
        'totalUnits': 0,
        'averageOccupancy': 0,
        'totalMonthlyRevenue': 0,
        'totalMonthlyExpenses': 0,
        'totalMonthlyNOI': 0,
        'averageCapRate': 0,
        'totalEquity': 0,
        'totalDebt': 0,
      };
    }

    final totalProperties = propertyMetrics.length.toDouble();
    final totalUnits = propertyMetrics.fold<int>(0, (sum, m) => sum + m.totalUnits);
    final occupiedUnits = propertyMetrics.fold<int>(0, (sum, m) => sum + m.occupiedUnits);
    final averageOccupancy = totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0.0;
    
    final totalMonthlyRevenue = propertyMetrics.fold<double>(0, (sum, m) => sum + m.monthlyRentCollected);
    final totalMonthlyExpenses = propertyMetrics.fold<double>(0, (sum, m) => sum + m.monthlyExpenses);
    final totalMonthlyNOI = totalMonthlyRevenue - totalMonthlyExpenses;
    
    final averageCapRate = propertyMetrics.fold<double>(0, (sum, m) => sum + m.capRate) / totalProperties;
    final totalEquity = propertyMetrics.fold<double>(0, (sum, m) => sum + m.equity);
    final totalDebt = propertyMetrics.fold<double>(0, (sum, m) => sum + m.totalDebt);

    return {
      'totalProperties': totalProperties,
      'totalUnits': totalUnits.toDouble(),
      'averageOccupancy': averageOccupancy,
      'totalMonthlyRevenue': totalMonthlyRevenue,
      'totalMonthlyExpenses': totalMonthlyExpenses,
      'totalMonthlyNOI': totalMonthlyNOI,
      'averageCapRate': averageCapRate,
      'totalEquity': totalEquity,
      'totalDebt': totalDebt,
    };
  }
}
