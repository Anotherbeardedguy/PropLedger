import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/cashflow_service.dart';

class ProfitLossCard extends StatelessWidget {
  final MonthlyCashflowSummary summary;
  final String currency;

  const ProfitLossCard({
    super.key,
    required this.summary,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profit & Loss Statement',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Revenue',
              [
                _buildLineItem('Rental Income', summary.rentIncome, Colors.green),
              ],
              summary.totalIncome,
              Colors.green,
            ),
            const Divider(height: 32),
            _buildSection(
              'Operating Expenses',
              [
                _buildLineItem('Loan Payments', summary.loanPayments, Colors.red),
                _buildLineItem('Property Upkeep', summary.upkeepCosts, Colors.red),
                _buildLineItem('Maintenance', summary.maintenanceCosts, Colors.red),
                _buildLineItem('Other Expenses', summary.otherExpenses, Colors.red),
              ],
              summary.totalExpenses,
              Colors.red,
            ),
            const Divider(height: 32),
            _buildNetProfit(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> items,
    double total,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ...items,
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total $title',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.format(total, currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineItem(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          Text(
            CurrencyFormatter.format(amount, currency),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfit() {
    final netProfit = summary.netCashflow;
    final isProfit = netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isProfit
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProfit ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isProfit ? 'Net Profit' : 'Net Loss',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Month',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(netProfit.abs(), currency),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isProfit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
