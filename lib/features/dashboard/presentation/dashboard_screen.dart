import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../properties/presentation/properties_screen.dart';
import '../../tenants/presentation/tenants_screen.dart';
import '../../rent_payments/presentation/rent_payments_screen.dart';
import '../widgets/upcoming_payments_card.dart';
import '../widgets/outstanding_rent_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PropLedger - Local Mode'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OutstandingRentCard(),
              const SizedBox(height: 16),
              const UpcomingPaymentsCard(),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildQuickActionCard(
                        context,
                        icon: Icons.home_work,
                        label: 'Properties',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PropertiesScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.people,
                        label: 'Tenants',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TenantsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.attach_money,
                        label: 'Rent',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RentPaymentsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionCard(
                        context,
                        icon: Icons.receipt,
                        label: 'Expenses',
                        onTap: () {},
                        enabled: false,
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: enabled ? 2 : 0,
      color: enabled ? null : Colors.grey[200],
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: enabled ? null : Colors.grey[600],
                ),
              ),
              if (!enabled)
                const Text(
                  '(Soon)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
