import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/tenant.dart';
import '../logic/tenants_notifier.dart';
import 'tenant_form_screen.dart';

class TenantDetailScreen extends ConsumerWidget {
  final String tenantId;

  const TenantDetailScreen({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantDetailProvider(tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              tenantAsync.whenData((tenant) {
                if (tenant != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TenantFormScreen(tenant: tenant),
                    ),
                  );
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context, ref);
            },
          ),
        ],
      ),
      body: tenantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
        data: (tenant) {
          if (tenant == null) {
            return const Center(child: Text('Tenant not found'));
          }

          final leaseEnd = tenant.leaseEnd;
          final leaseStart = tenant.leaseStart;
          final isLeaseActive = leaseEnd != null && leaseEnd.isAfter(DateTime.now());
          final leaseDuration = leaseStart != null && leaseEnd != null
              ? leaseEnd.difference(leaseStart).inDays
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                      style: TextStyle(
                        fontSize: 40,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Divider(),
                        _buildInfoRow(context, Icons.person, 'Name', tenant.name),
                        if (tenant.phone != null)
                          _buildInfoRow(context, Icons.phone, 'Phone', tenant.phone!),
                        if (tenant.email != null)
                          _buildInfoRow(context, Icons.email, 'Email', tenant.email!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Lease Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            if (isLeaseActive)
                              Chip(
                                label: const Text('Active'),
                                backgroundColor: Colors.green.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Chip(
                                label: const Text('Expired'),
                                backgroundColor: Colors.red.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const Divider(),
                        if (leaseStart != null)
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            'Lease Start',
                            DateFormat('MMM dd, yyyy').format(leaseStart),
                          ),
                        if (leaseEnd != null)
                          _buildInfoRow(
                            context,
                            Icons.event,
                            'Lease End',
                            DateFormat('MMM dd, yyyy').format(leaseEnd),
                          ),
                        if (leaseDuration != null)
                          _buildInfoRow(
                            context,
                            Icons.timelapse,
                            'Duration',
                            '${(leaseDuration / 30).round()} months',
                          ),
                        _buildInfoRow(
                          context,
                          Icons.schedule,
                          'Payment Term',
                          tenant.leaseTerm == LeaseTerm.monthly ? 'Monthly' : 'Annually',
                        ),
                        if (tenant.depositAmount != null) ...[
                          _buildInfoRow(
                            context,
                            Icons.account_balance_wallet,
                            'Deposit',
                            '\$${tenant.depositAmount!.toStringAsFixed(2)}',
                          ),
                          if (tenant.depositAmount! < 100)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: tenant.depositAmount! <= 0 
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: tenant.depositAmount! <= 0 ? Colors.red : Colors.orange,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: tenant.depositAmount! <= 0 ? Colors.red : Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tenant.depositAmount! <= 0
                                        ? 'Deposit depleted - Refill required'
                                        : 'Low deposit - Consider refilling',
                                      style: TextStyle(
                                        color: tenant.depositAmount! <= 0 ? Colors.red : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (tenant.notes != null && tenant.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(),
                          Text(tenant.notes!),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: const Text('Are you sure you want to delete this tenant? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(tenantsNotifierProvider(null).notifier).deleteTenant(tenantId);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tenant deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
