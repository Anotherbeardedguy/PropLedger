import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/loan_payment.dart';
import '../logic/loans_notifier.dart';

class RecordLoanPaymentScreen extends ConsumerStatefulWidget {
  final Loan loan;

  const RecordLoanPaymentScreen({super.key, required this.loan});

  @override
  ConsumerState<RecordLoanPaymentScreen> createState() => _RecordLoanPaymentScreenState();
}

class _RecordLoanPaymentScreenState extends ConsumerState<RecordLoanPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalAmountController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();

  DateTime _paymentDate = DateTime.now();

  @override
  void dispose() {
    _totalAmountController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  void _calculateSplit() {
    final total = double.tryParse(_totalAmountController.text);
    if (total != null && total > 0) {
      final monthlyRate = widget.loan.interestRate / 100 / 12;
      final interest = widget.loan.currentBalance * monthlyRate;
      final principal = total - interest;

      setState(() {
        _interestController.text = interest.toStringAsFixed(2);
        _principalController.text = principal.clamp(0, total).toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.loan.lender,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Current Balance: \$${widget.loan.currentBalance.toStringAsFixed(2)}'),
                    Text('Interest Rate: ${widget.loan.interestRate}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _totalAmountController,
              decoration: InputDecoration(
                labelText: 'Total Payment Amount *',
                border: const OutlineInputBorder(),
                prefixText: '\$ ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate),
                  onPressed: _calculateSplit,
                  tooltip: 'Calculate principal/interest split',
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calculateSplit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _principalController,
              decoration: const InputDecoration(
                labelText: 'Principal Amount *',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                helperText: 'Amount toward loan balance',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter principal amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestController,
              decoration: const InputDecoration(
                labelText: 'Interest Amount *',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                helperText: 'Interest portion of payment',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter interest amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }

                final principal = double.tryParse(_principalController.text) ?? 0;
                final interest = amount;
                final total = double.tryParse(_totalAmountController.text) ?? 0;

                if ((principal + interest - total).abs() > 0.01) {
                  return 'Principal + Interest must equal Total';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Payment Date: ${DateFormat('MMMM dd, yyyy').format(_paymentDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectPaymentDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _recordPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Record Payment'),
            ),
            const SizedBox(height: 8),
            Text(
              'This will update the loan balance from \$${widget.loan.currentBalance.toStringAsFixed(2)} to \$${_calculateNewBalance().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateNewBalance() {
    final principal = double.tryParse(_principalController.text) ?? 0;
    return (widget.loan.currentBalance - principal).clamp(0, widget.loan.currentBalance);
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: widget.loan.startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _recordPayment() async {
    if (_formKey.currentState!.validate()) {
      final paymentNotifier = ref.read(loanPaymentsNotifierProvider(widget.loan.id).notifier);
      final loanNotifier = ref.read(loansNotifierProvider.notifier);

      final principal = double.parse(_principalController.text);
      final interest = double.parse(_interestController.text);
      final total = double.parse(_totalAmountController.text);
      final newBalance = _calculateNewBalance();

      final payment = LoanPayment(
        id: const Uuid().v4(),
        loanId: widget.loan.id,
        paymentDate: _paymentDate,
        totalAmount: total,
        principalAmount: principal,
        interestAmount: interest,
        remainingBalance: newBalance,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      await paymentNotifier.createPayment(payment);

      final updatedLoan = widget.loan.copyWith(
        currentBalance: newBalance,
        updated: DateTime.now(),
      );
      await loanNotifier.updateLoan(updatedLoan);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment recorded. New balance: \$${newBalance.toStringAsFixed(2)}'),
          ),
        );
      }
    }
  }
}
