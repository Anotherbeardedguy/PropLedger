import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/rent_payment.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/unit.dart';
import '../../../data/models/tenant.dart';
import '../../../data/models/property.dart';
import '../../../core/services/property_performance_service.dart';
import '../../../core/utils/formatters.dart';

class PropertyPerformanceCard extends ConsumerWidget {
  final List<RentPayment> rentPayments;
  final List<Expense> expenses;
  final List<Loan> loans;
  final List<Unit> units;
  final List<Tenant> tenants;
  final List<Property> properties;
  final String currency;

  const PropertyPerformanceCard({
    super.key,
    required this.rentPayments,
    required this.expenses,
    required this.loans,
    required this.units,
    required this.tenants,
    required this.properties,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (properties.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.apartment, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Property Performance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Icon(Icons.insights, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No properties yet', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final service = PropertyPerformanceService();
    final propertyMetrics = service.calculateAllPropertiesPerformance(
      properties: properties,
      allUnits: units,
      allPayments: rentPayments,
      allExpenses: expenses,
      allLoans: loans,
      allTenants: tenants,
    );

    // Sort by NOI descending
    propertyMetrics.sort((a, b) => b.monthlyNOI.compareTo(a.monthlyNOI));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apartment, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Property Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...propertyMetrics.map((metrics) => _buildPropertyCard(context, metrics)),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyPerformanceMetrics metrics) {
    final noiColor = metrics.monthlyNOI >= 0 ? Colors.green : Colors.red;
    final occupancyColor = metrics.occupancyRate >= 80 ? Colors.green : 
                           metrics.occupancyRate >= 50 ? Colors.orange : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metrics.propertyName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: occupancyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${metrics.occupancyRate.toStringAsFixed(0)}% Occupied',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: occupancyColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricItem('Units', '${metrics.occupiedUnits}/${metrics.totalUnits}', Icons.meeting_room)),
                Expanded(child: _buildMetricItem('Revenue/Unit', CurrencyFormatter.format(metrics.revenuePerUnit, currency), Icons.attach_money)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMetricItem('Monthly Income', CurrencyFormatter.format(metrics.monthlyRentCollected, currency), Icons.arrow_upward, Colors.green)),
                Expanded(child: _buildMetricItem('Monthly Expenses', CurrencyFormatter.format(metrics.monthlyExpenses, currency), Icons.arrow_downward, Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: noiColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: noiColor, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly NOI', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(metrics.monthlyNOI, currency),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: noiColor),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildSmallMetric('Cap Rate', '${metrics.capRate.toStringAsFixed(1)}%'),
                      const SizedBox(height: 4),
                      _buildSmallMetric('ROI', '${metrics.roi.toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMetric(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
