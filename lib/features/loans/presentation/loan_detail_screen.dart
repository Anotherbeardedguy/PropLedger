import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/loan_payment.dart';
import '../../../data/models/property.dart';
import '../logic/loans_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import 'add_edit_loan_screen.dart';
import 'record_loan_payment_screen.dart';

class LoanDetailScreen extends ConsumerWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(loanPaymentsNotifierProvider(loan.id));
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final property = propertiesAsync.maybeWhen(
      data: (properties) => properties.cast<Property?>().firstWhere(
            (p) => p?.id == loan.propertyId,
            orElse: () => null,
          ),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.lender),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context, loan),
          ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (property != null)
                    _buildDetailRow('Property', property.name),
                  if (loan.loanType != null)
                    _buildDetailRow('Loan Type', loan.loanType!),
                  _buildDetailRow('Lender', loan.lender),
                  _buildDetailRow(
                    'Original Amount',
                    '\$${loan.originalAmount.toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    'Current Balance',
                    '\$${loan.currentBalance.toStringAsFixed(2)}',
                    valueColor: Colors.red.shade700,
                  ),
                  _buildDetailRow(
                    'Total Paid',
                    '\$${loan.totalPaid.toStringAsFixed(2)}',
                    valueColor: Colors.green.shade700,
                  ),
                  _buildDetailRow(
                    'Interest Rate',
                    '${loan.interestRate}% ${loan.interestType == InterestType.fixed ? 'Fixed' : 'Variable'}',
                  ),
                  _buildDetailRow(
                    'Payment Frequency',
                    _getFrequencyLabel(loan.paymentFrequency),
                  ),
                  _buildDetailRow(
                    'Start Date',
                    DateFormat('MMM dd, yyyy').format(loan.startDate),
                  ),
                  if (loan.endDate != null)
                    _buildDetailRow(
                      'End Date',
                      DateFormat('MMM dd, yyyy').format(loan.endDate!),
                    ),
                  if (loan.notes != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(loan.notes!),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _navigateToRecordPayment(context, loan),
                  icon: const Icon(Icons.add),
                  label: const Text('Record Payment'),
                ),
              ],
            ),
          ),
          paymentsAsync.when(
            data: (payments) {
              if (payments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.payment, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No payments recorded',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: payments.map((payment) => _buildPaymentCard(context, payment, ref)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, LoanPayment payment, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.payment, color: Colors.green.shade700),
        ),
        title: Text(
          '\$${payment.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM dd, yyyy').format(payment.paymentDate)),
            Text(
              'Principal: \$${payment.principalAmount.toStringAsFixed(2)} | Interest: \$${payment.interestAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDeletePayment(context, payment, ref),
        ),
      ),
    );
  }

  String _getFrequencyLabel(PaymentFrequency frequency) {
    switch (frequency) {
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      case PaymentFrequency.annually:
        return 'Annually';
    }
  }

  void _navigateToEdit(BuildContext context, Loan loan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditLoanScreen(loan: loan),
      ),
    );
  }

  void _navigateToRecordPayment(BuildContext context, Loan loan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordLoanPaymentScreen(loan: loan),
      ),
    );
  }

  void _confirmDeletePayment(BuildContext context, LoanPayment payment, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notifier = ref.read(loanPaymentsNotifierProvider(loan.id).notifier);
              await notifier.deletePayment(payment.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
