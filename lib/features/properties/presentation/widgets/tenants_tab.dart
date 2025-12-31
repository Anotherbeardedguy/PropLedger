import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../logic/units_notifier.dart';
import '../../../tenants/logic/tenants_notifier.dart';
import '../../../tenants/presentation/tenant_detail_screen.dart';
import '../../../tenants/presentation/tenant_form_screen.dart';

class TenantsTab extends ConsumerWidget {
  final String propertyId;

  const TenantsTab({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsNotifierProvider(propertyId));
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));

    return unitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading units: $error')),
      data: (propertyUnits) {
        // Get unit IDs for this property
        final propertyUnitIds = propertyUnits.map((u) => u.id).toSet();

        return tenantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(tenantsNotifierProvider(null).notifier).loadTenants();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (allTenants) {
            // Filter tenants: only those in this property's units
            final tenants = allTenants.where((t) {
              return t.unitId.isNotEmpty && propertyUnitIds.contains(t.unitId);
            }).toList();

        if (tenants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tenants yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add tenants to units in this property',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TenantFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Tenant'),
                ),
              ],
            ),
          );
        }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                final tenant = tenants[index];
                final leaseEnd = tenant.leaseEnd;
                final isLeaseExpiringSoon = leaseEnd != null &&
                    leaseEnd.isAfter(DateTime.now()) &&
                    leaseEnd.isBefore(DateTime.now().add(const Duration(days: 60)));
                final isLeaseActive = leaseEnd != null && leaseEnd.isAfter(DateTime.now());

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      tenant.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tenant.phone != null) ...[
                          const SizedBox(height: 4),
                          Text(tenant.phone!),
                        ],
                        if (leaseEnd != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Lease ends: ${DateFormat('MMM dd, yyyy').format(leaseEnd)}',
                                style: TextStyle(
                                  color: isLeaseExpiringSoon ? Colors.orange : null,
                                  fontWeight: isLeaseExpiringSoon ? FontWeight.bold : null,
                                ),
                              ),
                              if (isLeaseExpiringSoon) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        isLeaseActive ? 'Active' : 'Expired',
                        style: TextStyle(
                          color: isLeaseActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: isLeaseActive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TenantDetailScreen(tenantId: tenant.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
