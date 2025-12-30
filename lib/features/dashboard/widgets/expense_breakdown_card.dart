import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../core/utils/formatters.dart';
import '../../../features/settings/logic/settings_notifier.dart';
import '../../expenses/logic/expenses_notifier.dart';

class ExpenseBreakdownCard extends ConsumerWidget {
  const ExpenseBreakdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expense Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last 30 days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            expensesAsync.when(
              data: (expenses) {
                final breakdown = _calculateBreakdown(expenses);
                
                if (breakdown.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No expenses in the last 30 days',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildPieChart(context, breakdown),
                    const SizedBox(height: 16),
                    _buildLegend(context, breakdown, settings),
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
            ),
          ],
        ),
      ),
    );
  }

  List<CategoryBreakdown> _calculateBreakdown(List<dynamic> expenses) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentExpenses = expenses.where((e) => e.date.isAfter(thirtyDaysAgo)).toList();

    if (recentExpenses.isEmpty) return [];

    final Map<String, double> categoryTotals = {};
    
    for (final expense in recentExpenses) {
      final category = expense.category ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }

    final total = categoryTotals.values.fold<double>(0, (sum, amount) => sum + amount);

    final breakdown = categoryTotals.entries.map((entry) {
      return CategoryBreakdown(
        category: entry.key,
        amount: entry.value,
        percentage: (entry.value / total * 100),
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return breakdown;
  }

  Widget _buildPieChart(BuildContext context, List<CategoryBreakdown> breakdown) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: PieChartPainter(breakdown),
        child: Container(),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<CategoryBreakdown> breakdown, settings) {
    return Column(
      children: breakdown.map((item) {
        final color = _getCategoryColor(breakdown.indexOf(item));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.category,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '${item.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(item.amount, settings.currency),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }
}

class CategoryBreakdown {
  final String category;
  final double amount;
  final double percentage;

  CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class PieChartPainter extends CustomPainter {
  final List<CategoryBreakdown> breakdown;

  PieChartPainter(this.breakdown);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < breakdown.length; i++) {
      final sweepAngle = (breakdown[i].percentage / 100) * 2 * math.pi;
      final color = _getCategoryColor(i);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw white circle in center for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
