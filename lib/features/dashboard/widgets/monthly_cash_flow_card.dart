import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/settings/logic/settings_notifier.dart';
import '../../rent_payments/logic/rent_payments_notifier.dart';
import '../../expenses/logic/expenses_notifier.dart';

class MonthlyCashFlowCard extends ConsumerWidget {
  const MonthlyCashFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(rentPaymentsNotifierProvider(null));
    final expensesAsync = ref.watch(expensesNotifierProvider);
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
                  Icons.show_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Cash Flow',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            paymentsAsync.when(
              data: (payments) {
                return expensesAsync.when(
                  data: (expenses) {
                    final monthlyData = _calculateMonthlyData(payments, expenses);
                    
                    if (monthlyData.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No financial data yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        _buildCashFlowChart(context, monthlyData, settings),
                        const SizedBox(height: 16),
                        _buildSummary(context, monthlyData, settings),
                      ],
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

  List<MonthlyFlowData> _calculateMonthlyData(
    List<dynamic> payments,
    List<dynamic> expenses,
  ) {
    final now = DateTime.now();
    final Map<String, MonthlyFlowData> monthlyMap = {};

    // Generate last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyMap[key] = MonthlyFlowData(
        month: month,
        income: 0,
        expenses: 0,
      );
    }

    // Aggregate income from paid rent payments
    for (final payment in payments) {
      if (payment.paidDate != null) {
        final paidDate = payment.paidDate!;
        final key = '${paidDate.year}-${paidDate.month.toString().padLeft(2, '0')}';
        if (monthlyMap.containsKey(key)) {
          monthlyMap[key] = monthlyMap[key]!.copyWith(
            income: monthlyMap[key]!.income + payment.amount,
          );
        }
      }
    }

    // Aggregate expenses
    for (final expense in expenses) {
      final expenseDate = expense.date;
      final key = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';
      if (monthlyMap.containsKey(key)) {
        monthlyMap[key] = monthlyMap[key]!.copyWith(
          expenses: monthlyMap[key]!.expenses + expense.amount,
        );
      }
    }

    return monthlyMap.values.toList()..sort((a, b) => a.month.compareTo(b.month));
  }

  Widget _buildCashFlowChart(
    BuildContext context,
    List<MonthlyFlowData> data,
    settings,
  ) {
    final maxValue = data.fold<double>(
      0,
      (max, d) => [max, d.income, d.expenses].reduce((a, b) => a > b ? a : b),
    );

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((monthData) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildBar(
                    context,
                    monthData.income,
                    maxValue,
                    Colors.green,
                  ),
                  const SizedBox(height: 4),
                  _buildBar(
                    context,
                    monthData.expenses,
                    maxValue,
                    Colors.red,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMonthLabel(monthData.month),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    double value,
    double maxValue,
    Color color,
  ) {
    final height = maxValue > 0 ? (value / maxValue * 70).clamp(2.0, 70.0) : 2.0;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: value > 0
          ? Center(
              child: Text(
                CurrencyFormatter.formatCompact(value, 'USD'),
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSummary(
    BuildContext context,
    List<MonthlyFlowData> data,
    settings,
  ) {
    final totalIncome = data.fold<double>(0, (sum, d) => sum + d.income);
    final totalExpenses = data.fold<double>(0, (sum, d) => sum + d.expenses);
    final netCashFlow = totalIncome - totalExpenses;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: netCashFlow >= 0
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            'Income',
            CurrencyFormatter.format(totalIncome, settings.currency),
            Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildSummaryItem(
            context,
            'Expenses',
            CurrencyFormatter.format(totalExpenses, settings.currency),
            Colors.red,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildSummaryItem(
            context,
            'Net',
            CurrencyFormatter.format(netCashFlow, settings.currency),
            netCashFlow >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getMonthLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }
}

class MonthlyFlowData {
  final DateTime month;
  final double income;
  final double expenses;

  MonthlyFlowData({
    required this.month,
    required this.income,
    required this.expenses,
  });

  MonthlyFlowData copyWith({
    DateTime? month,
    double? income,
    double? expenses,
  }) {
    return MonthlyFlowData(
      month: month ?? this.month,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
    );
  }
}
