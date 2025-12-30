import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/enhanced_empty_state.dart';
import '../../../core/widgets/enhanced_error_display.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../logic/tenants_notifier.dart';
import 'tenant_detail_screen.dart';
import 'tenant_form_screen.dart';

class TenantsScreen extends ConsumerWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
      ),
      body: tenantsAsync.when(
        loading: () => const ListSkeleton(itemCount: 5),
        error: (error, stack) => EnhancedErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.read(tenantsNotifierProvider(null).notifier).loadTenants(),
        ),
        data: (tenants) {
          if (tenants.isEmpty) {
            return EnhancedEmptyState(
              icon: Icons.people_outline,
              title: 'No Tenants Yet',
              message: 'Add your first tenant to start managing your rental occupancy.',
              actionLabel: 'Add Tenant',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TenantFormScreen(),
                  ),
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(tenantsNotifierProvider(null).notifier).loadTenants();
            },
            child: ListView.builder(
              itemCount: tenants.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final tenant = tenants[index];
                final leaseEnd = tenant.leaseEnd;
                final isLeaseExpiringSoon = leaseEnd != null &&
                    leaseEnd.isAfter(DateTime.now()) &&
                    leaseEnd.isBefore(DateTime.now().add(const Duration(days: 60)));

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
                          Text(
                            'Lease ends: ${DateFormat('MMM dd, yyyy').format(leaseEnd)}',
                            style: TextStyle(
                              color: isLeaseExpiringSoon ? Colors.orange : null,
                              fontWeight: isLeaseExpiringSoon ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isLeaseExpiringSoon
                        ? const Icon(Icons.warning_amber, color: Colors.orange)
                        : const Icon(Icons.chevron_right),
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
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TenantFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
