import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/settings/logic/settings_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../rent_payments/logic/rent_payments_notifier.dart';
import '../../expenses/logic/expenses_notifier.dart';
import '../../loans/logic/loans_notifier.dart';

class PropertyFinancialSnapshotCard extends ConsumerWidget {
  const PropertyFinancialSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final paymentsAsync = ref.watch(rentPaymentsNotifierProvider(null));
    final expensesAsync = ref.watch(expensesNotifierProvider);
    final loansAsync = ref.watch(loansNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Property Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            propertiesAsync.when(
              data: (properties) {
                if (properties.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No properties yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return paymentsAsync.when(
                  data: (payments) => expensesAsync.when(
                    data: (expenses) => loansAsync.when(
                      data: (loans) {
                        return Column(
                          children: properties.map((property) {
                            final snapshot = _calculateSnapshot(
                              property,
                              payments,
                              expenses,
                              loans,
                            );
                            return _buildPropertyRow(context, snapshot, settings);
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PropertySnapshot _calculateSnapshot(
    property,
    List<dynamic> allPayments,
    List<dynamic> allExpenses,
    List<dynamic> allLoans,
  ) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Filter data for this property (last 30 days)
    final income = allPayments
        .where((p) =>
            p.paidDate != null &&
            p.paidDate!.isAfter(thirtyDaysAgo))
        .fold<double>(0, (sum, p) => sum + p.amount);

    final expenses = allExpenses
        .where((e) =>
            e.propertyId == property.id &&
            e.date.isAfter(thirtyDaysAgo))
        .fold<double>(0, (sum, e) => sum + e.amount);

    final propertyLoans = allLoans.where((l) => l.propertyId == property.id).toList();
    final totalDebt = propertyLoans.fold<double>(
      0,
      (sum, l) => sum + (l.originalAmount - l.totalPaid),
    );

    final noi = income - expenses;
    final equity = (property.estimatedValue ?? 0) - totalDebt;

    return PropertySnapshot(
      propertyName: property.name,
      income: income,
      expenses: expenses,
      noi: noi,
      equity: equity,
      estimatedValue: property.estimatedValue ?? 0,
    );
  }

  Widget _buildPropertyRow(BuildContext context, PropertySnapshot snapshot, settings) {
    final noiColor = snapshot.noi >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    snapshot.propertyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: noiColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NOI: ${CurrencyFormatter.format(snapshot.noi, settings.currency)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: noiColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Income',
                    CurrencyFormatter.formatCompact(snapshot.income, settings.currency),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Expenses',
                    CurrencyFormatter.formatCompact(snapshot.expenses, settings.currency),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    'Equity',
                    CurrencyFormatter.formatCompact(snapshot.equity, settings.currency),
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class PropertySnapshot {
  final String propertyName;
  final double income;
  final double expenses;
  final double noi;
  final double equity;
  final double estimatedValue;

  PropertySnapshot({
    required this.propertyName,
    required this.income,
    required this.expenses,
    required this.noi,
    required this.equity,
    required this.estimatedValue,
  });
}
