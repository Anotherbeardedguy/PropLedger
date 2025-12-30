import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        data: (tenants) {
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
                    'Add your first tenant to get started',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
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
