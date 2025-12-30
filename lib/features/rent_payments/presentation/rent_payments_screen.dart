import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/rent_payment.dart';
import '../logic/rent_payments_notifier.dart';
import 'payment_form_screen.dart';

class RentPaymentsScreen extends ConsumerWidget {
  const RentPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(rentPaymentsNotifierProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rent Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Filter functionality
            },
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
          if (payments.isEmpty) {
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
                    'No payments yet',
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

          final outstanding = payments.where((p) => p.status != PaymentStatus.paid).toList();
          final paid = payments.where((p) => p.status == PaymentStatus.paid).toList();

          return Column(
            children: [
              if (outstanding.isNotEmpty)
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
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Outstanding'),
                          Tab(text: 'Paid'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPaymentList(context, ref, outstanding, isOutstanding: true),
                            _buildPaymentList(context, ref, paid, isOutstanding: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildPaymentList(BuildContext context, WidgetRef ref, List<RentPayment> payments, {required bool isOutstanding}) {
    if (payments.isEmpty) {
      return Center(
        child: Text(
          isOutstanding ? 'No outstanding payments' : 'No paid payments',
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
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: payment.status == PaymentStatus.paid
                  ? Colors.green
                  : isLate
                      ? Colors.red
                      : Colors.orange,
              child: Icon(
                payment.status == PaymentStatus.paid
                    ? Icons.check
                    : Icons.payment,
                color: Colors.white,
              ),
            ),
            title: Text(
              '\$${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Due: ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}'),
                if (payment.paidDate != null)
                  Text('Paid: ${DateFormat('MMM dd, yyyy').format(payment.paidDate!)}'),
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
            trailing: isOutstanding
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () {
                      _markAsPaid(context, ref, payment);
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

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref, RentPayment payment) async {
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
