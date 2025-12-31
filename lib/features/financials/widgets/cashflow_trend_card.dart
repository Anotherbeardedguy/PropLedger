import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/cashflow_service.dart';
import '../../../data/models/rent_payment.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/maintenance_task.dart';
import '../../../data/models/unit.dart';

class CashflowTrendCard extends StatelessWidget {
  final CashflowService cashflowService;
  final List<RentPayment> rentPayments;
  final List<Loan> loans;
  final List<Unit> units;
  final List<Expense> expenses;
  final List<MaintenanceTask> maintenanceTasks;
  final String currency;

  const CashflowTrendCard({
    super.key,
    required this.cashflowService,
    required this.rentPayments,
    required this.loans,
    required this.units,
    required this.expenses,
    required this.maintenanceTasks,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final projections = cashflowService.calculateAnnualProjection(
      rentPayments: rentPayments,
      loans: loans,
      units: units,
      expenses: expenses,
      maintenanceTasks: maintenanceTasks,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '12-Month Cashflow Trend',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                _buildChartData(projections),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<MonthlyCashflowSummary> projections) {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final netSpots = <FlSpot>[];

    for (int i = 0; i < projections.length; i++) {
      final summary = projections[i];
      incomeSpots.add(FlSpot(i.toDouble(), summary.totalIncome));
      expenseSpots.add(FlSpot(i.toDouble(), summary.totalExpenses));
      netSpots.add(FlSpot(i.toDouble(), summary.netCashflow));
    }

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: incomeSpots,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withValues(alpha: 0.1),
          ),
        ),
        LineChartBarData(
          spots: expenseSpots,
          color: Colors.red,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withValues(alpha: 0.1),
          ),
        ),
        LineChartBarData(
          spots: netSpots,
          color: Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                CurrencyFormatter.formatCompact(value, currency),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              final index = value.toInt();
              if (index >= 0 && index < months.length) {
                return Text(
                  months[index],
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(show: false),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Income', Colors.green),
        _buildLegendItem('Expenses', Colors.red),
        _buildLegendItem('Net', Colors.blue),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
