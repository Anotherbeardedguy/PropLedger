import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/rent_payment.dart';
import '../../tenants/logic/tenants_notifier.dart';
import '../../properties/logic/units_notifier.dart';
import '../logic/rent_payments_notifier.dart';
import 'payment_form_screen.dart';

enum PaymentFilter { all, outstanding, paid, late }

class RentPaymentsScreen extends ConsumerStatefulWidget {
  const RentPaymentsScreen({super.key});

  @override
  ConsumerState<RentPaymentsScreen> createState() => _RentPaymentsScreenState();
}

class _RentPaymentsScreenState extends ConsumerState<RentPaymentsScreen> {
  PaymentFilter _currentFilter = PaymentFilter.all;

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(rentPaymentsNotifierProvider(null));
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));
    final unitsAsync = ref.watch(unitsNotifierProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Payments'),
        actions: [
          PopupMenuButton<PaymentFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: PaymentFilter.all,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 12),
                    Text('All Payments'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: PaymentFilter.outstanding,
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Outstanding'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: PaymentFilter.late,
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Late Payments'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: PaymentFilter.paid,
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Paid'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: paymentsAsync.when(
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
                  ref.read(rentPaymentsNotifierProvider(null).notifier).loadPayments();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (payments) {
          // Apply filter
          final filteredPayments = payments.where((payment) {
            switch (_currentFilter) {
              case PaymentFilter.all:
                return true;
              case PaymentFilter.outstanding:
                return payment.status != PaymentStatus.paid;
              case PaymentFilter.late:
                return payment.status == PaymentStatus.late;
              case PaymentFilter.paid:
                return payment.status == PaymentStatus.paid;
            }
          }).toList();

          if (filteredPayments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentFilter == PaymentFilter.all 
                        ? 'No payments yet'
                        : 'No ${_currentFilter.name} payments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Record your first rent payment',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaymentFormScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment'),
                  ),
                ],
              ),
            );
          }

          return tenantsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading tenants: $error')),
            data: (tenants) {
              return unitsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error loading units: $error')),
                data: (units) {
                  final outstanding = filteredPayments.where((p) => p.status != PaymentStatus.paid).toList();
                  
                  return Column(
                    children: [
                      if (outstanding.isNotEmpty && _currentFilter != PaymentFilter.paid)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.orange.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Outstanding Payments',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${outstanding.length} payment(s) - \$${outstanding.fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: _buildPaymentList(
                          filteredPayments, 
                          tenants, 
                          units,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PaymentFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentList(
    List<RentPayment> payments,
    List<dynamic> tenants,
    List<dynamic> units,
  ) {
    if (payments.isEmpty) {
      return Center(
        child: Text(
          'No payments',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final isLate = payment.status == PaymentStatus.late;
        final isPaid = payment.status == PaymentStatus.paid;
        
        // Get tenant and unit info
        final tenant = tenants.firstWhere(
          (t) => t.id == payment.tenantId,
          orElse: () => null,
        );
        final unit = units.firstWhere(
          (u) => u.id == payment.unitId,
          orElse: () => null,
        );
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isPaid
                  ? Colors.green
                  : isLate
                      ? Colors.red
                      : Colors.orange,
              child: Icon(
                isPaid ? Icons.check : Icons.payment,
                color: Colors.white,
              ),
            ),
            title: Text(
              tenant?.name ?? 'Unknown Tenant',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (unit != null)
                  Text(
                    'Unit: ${unit.unitName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '\$${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Due: ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}'),
                if (payment.paidDate != null)
                  Text(
                    'Paid: ${DateFormat('MMM dd, yyyy').format(payment.paidDate!)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                if (isLate && payment.daysOverdue > 0)
                  Text(
                    '${payment.daysOverdue} days overdue',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: !isPaid
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () {
                      _markAsPaid(context, payment);
                    },
                  )
                : Chip(
                    label: const Text(
                      'Paid',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _markAsPaid(BuildContext context, RentPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Mark \$${payment.amount.toStringAsFixed(2)} as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(rentPaymentsNotifierProvider(null).notifier)
          .markAsPaid(payment.id, DateTime.now());
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment marked as paid')),
        );
      }
    }
  }
}
