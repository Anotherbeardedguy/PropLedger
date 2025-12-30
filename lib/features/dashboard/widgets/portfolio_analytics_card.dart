import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/settings/logic/settings_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../loans/logic/loans_notifier.dart';
import '../../tenants/logic/tenants_notifier.dart';

class PortfolioAnalyticsCard extends ConsumerWidget {
  const PortfolioAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final loansAsync = ref.watch(loansNotifierProvider);
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));
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
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Portfolio Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Portfolio Value
            propertiesAsync.when(
              data: (properties) {
                final totalValue = properties.fold<double>(
                  0.0,
                  (sum, p) => sum + (p.estimatedValue ?? 0),
                );
                
                return _buildAnalyticRow(
                  context,
                  'Total Portfolio Value',
                  CurrencyFormatter.format(totalValue, settings.currency),
                  Colors.blue,
                  Icons.home_work,
                );
              },
              loading: () => _buildLoadingRow('Total Portfolio Value'),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const Divider(height: 24),
            
            // Total Equity (Value - Loans)
            propertiesAsync.when(
              data: (properties) {
                final totalValue = properties.fold<double>(
                  0.0,
                  (sum, p) => sum + (p.estimatedValue ?? 0),
                );
                
                return loansAsync.when(
                  data: (loans) {
                    final totalDebt = loans.fold<double>(
                      0.0,
                      (sum, l) => sum + l.currentBalance,
                    );
                    final equity = totalValue - totalDebt;
                    
                    return _buildAnalyticRow(
                      context,
                      'Total Equity',
                      CurrencyFormatter.format(equity, settings.currency),
                      Colors.green,
                      Icons.trending_up,
                    );
                  },
                  loading: () => _buildLoadingRow('Total Equity'),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => _buildLoadingRow('Total Equity'),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const Divider(height: 24),
            
            // Occupancy Rate
            tenantsAsync.when(
              data: (tenants) {
                if (tenants.isEmpty) {
                  return _buildAnalyticRow(
                    context,
                    'Occupancy Rate',
                    'No tenants',
                    Colors.orange,
                    Icons.people,
                  );
                }
                
                final activeLeases = tenants.where((tenant) {
                  if (tenant.leaseEnd == null || tenant.leaseStart == null) return false;
                  final now = DateTime.now();
                  return tenant.leaseStart!.isBefore(now) && 
                         tenant.leaseEnd!.isAfter(now);
                }).length;
                
                final occupancyRate = (activeLeases / tenants.length * 100);
                
                return _buildAnalyticRow(
                  context,
                  'Occupancy Rate',
                  '${occupancyRate.toStringAsFixed(1)}%',
                  occupancyRate >= 80 ? Colors.green : Colors.orange,
                  Icons.people,
                );
              },
              loading: () => _buildLoadingRow('Occupancy Rate'),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            const Divider(height: 24),
            
            // Property Count
            propertiesAsync.when(
              data: (properties) {
                return _buildAnalyticRow(
                  context,
                  'Total Properties',
                  properties.length.toString(),
                  Colors.purple,
                  Icons.business,
                );
              },
              loading: () => _buildLoadingRow('Total Properties'),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticRow(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
