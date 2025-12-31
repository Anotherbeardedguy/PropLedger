import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/cashflow_service.dart';
import '../../../features/settings/logic/settings_notifier.dart';
import '../../rent_payments/logic/rent_payments_notifier.dart';
import '../../expenses/logic/expenses_notifier.dart';
import '../../loans/logic/loans_notifier.dart';
import '../../maintenance/logic/maintenance_notifier.dart';
import '../../properties/logic/units_notifier.dart';
import '../../financials/presentation/financials_screen.dart';

class MonthlyCashFlowCard extends ConsumerWidget {
  const MonthlyCashFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(rentPaymentsNotifierProvider(null));
    final expensesAsync = ref.watch(expensesNotifierProvider);
    final loansAsync = ref.watch(loansNotifierProvider);
    final maintenanceAsync = ref.watch(maintenanceNotifierProvider);
    final unitsAsync = ref.watch(unitsNotifierProvider(null));
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
                Expanded(
                  child: Text(
                    'Monthly Cash Flow',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FinancialsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('View Reports'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            paymentsAsync.when(
              data: (payments) {
                return expensesAsync.when(
                  data: (expenses) {
                    return loansAsync.when(
                      data: (loans) {
                        return maintenanceAsync.when(
                          data: (maintenance) {
                            return unitsAsync.when(
                              data: (units) {
                                final cashflowService = CashflowService();
                                final currentMonth = cashflowService.calculateMonthlyCashflow(
                                  rentPayments: payments,
                                  loans: loans,
                                  units: units,
                                  expenses: expenses,
                                  maintenanceTasks: maintenance,
                                );

                                return Column(
                                  children: [
                                    _buildDetailedBreakdown(context, currentMonth, settings),
                                    const SizedBox(height: 16),
                                    _buildEnhancedSummary(context, currentMonth, settings),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Center(child: Text('Error: $e')),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
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

  Widget _buildDetailedBreakdown(
    BuildContext context,
    MonthlyCashflowSummary summary,
    settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildBreakdownItem(
          'Rent Collected',
          summary.rentIncome,
          settings.currency,
          Icons.payments,
          Colors.green,
        ),
        const Divider(height: 24),
        Text(
          'Expenses',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _buildBreakdownItem(
          'Loan Payments',
          summary.loanPayments,
          settings.currency,
          Icons.account_balance,
          Colors.red,
        ),
        const SizedBox(height: 4),
        _buildBreakdownItem(
          'Upkeep Costs',
          summary.upkeepCosts,
          settings.currency,
          Icons.build,
          Colors.orange,
        ),
        const SizedBox(height: 4),
        _buildBreakdownItem(
          'Maintenance',
          summary.maintenanceCosts,
          settings.currency,
          Icons.handyman,
          Colors.deepOrange,
        ),
        const SizedBox(height: 4),
        _buildBreakdownItem(
          'Other Expenses',
          summary.otherExpenses,
          settings.currency,
          Icons.receipt_long,
          Colors.red[300]!,
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double amount,
    String currency,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          Text(
            CurrencyFormatter.format(amount, currency),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummary(
    BuildContext context,
    MonthlyCashflowSummary summary,
    settings,
  ) {
    final netCashFlow = summary.netCashflow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: netCashFlow >= 0
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: netCashFlow >= 0 ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            'Total Income',
            CurrencyFormatter.format(summary.totalIncome, settings.currency),
            Colors.green,
          ),
          Container(width: 1, height: 50, color: Colors.grey[300]),
          _buildSummaryItem(
            context,
            'Total Expenses',
            CurrencyFormatter.format(summary.totalExpenses, settings.currency),
            Colors.red,
          ),
          Container(width: 1, height: 50, color: Colors.grey[300]),
          _buildSummaryItem(
            context,
            'Net Cashflow',
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

}
