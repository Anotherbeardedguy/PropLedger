import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/enhanced_empty_state.dart';
import '../../../core/widgets/enhanced_error_display.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../logic/tenants_notifier.dart';
import 'tenant_detail_screen.dart';
import 'tenant_form_screen.dart';

class TenantsScreen extends ConsumerStatefulWidget {
  const TenantsScreen({super.key});

  @override
  ConsumerState<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends ConsumerState<TenantsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text('Tenants')
            : TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search tenants...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _searchQuery = ' ';
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
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

          // Apply search filter
          final filteredTenants = tenants.where((tenant) {
            if (_searchQuery.trim().isEmpty) return true;
            final query = _searchQuery.trim().toLowerCase();
            return tenant.name.toLowerCase().contains(query) ||
                   (tenant.email?.toLowerCase().contains(query) ?? false) ||
                   (tenant.phone?.toLowerCase().contains(query) ?? false);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(tenantsNotifierProvider(null).notifier).loadTenants();
            },
            child: ListView.builder(
              itemCount: filteredTenants.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final tenant = filteredTenants[index];
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
