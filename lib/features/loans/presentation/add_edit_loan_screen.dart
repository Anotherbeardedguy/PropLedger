import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../data/models/loan.dart';
import '../logic/loans_notifier.dart';
import '../../properties/logic/properties_notifier.dart';

class AddEditLoanScreen extends ConsumerStatefulWidget {
  final Loan? loan;

  const AddEditLoanScreen({super.key, this.loan});

  @override
  ConsumerState<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends ConsumerState<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lenderController = TextEditingController();
  final _loanTypeController = TextEditingController();
  final _originalAmountController = TextEditingController();
  final _currentBalanceController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPropertyId;
  InterestType _interestType = InterestType.fixed;
  PaymentFrequency _paymentFrequency = PaymentFrequency.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final loan = widget.loan!;
      _lenderController.text = loan.lender;
      _loanTypeController.text = loan.loanType ?? '';
      _originalAmountController.text = loan.originalAmount.toString();
      _currentBalanceController.text = loan.currentBalance.toString();
      _interestRateController.text = loan.interestRate.toString();
      _notesController.text = loan.notes ?? '';
      _selectedPropertyId = loan.propertyId;
      _interestType = loan.interestType;
      _paymentFrequency = loan.paymentFrequency;
      _startDate = loan.startDate;
      _endDate = loan.endDate;
    }
  }

  @override
  void dispose() {
    _lenderController.dispose();
    _loanTypeController.dispose();
    _originalAmountController.dispose();
    _currentBalanceController.dispose();
    _interestRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Loan' : 'Add Loan'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            propertiesAsync.when(
              data: (properties) => DropdownButtonFormField<String>(
                value: _selectedPropertyId,
                decoration: const InputDecoration(
                  labelText: 'Property *',
                  border: OutlineInputBorder(),
                ),
                items: properties.map((property) {
                  return DropdownMenuItem(
                    value: property.id,
                    child: Text(property.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPropertyId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a property';
                  }
                  return null;
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lenderController,
              decoration: const InputDecoration(
                labelText: 'Lender *',
                border: OutlineInputBorder(),
                helperText: 'Bank or lender name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter lender name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loanTypeController,
              decoration: const InputDecoration(
                labelText: 'Loan Type (Optional)',
                border: OutlineInputBorder(),
                helperText: 'e.g., Mortgage, Renovation, Bridge',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _originalAmountController,
              decoration: const InputDecoration(
                labelText: 'Original Amount *',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter original amount';
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
              controller: _currentBalanceController,
              decoration: const InputDecoration(
                labelText: 'Current Balance *',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                helperText: 'Remaining amount owed',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter current balance';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Please enter a valid amount';
                }
                final original = double.tryParse(_originalAmountController.text);
                if (original != null && amount > original) {
                  return 'Balance cannot exceed original amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateController,
              decoration: const InputDecoration(
                labelText: 'Interest Rate *',
                border: OutlineInputBorder(),
                suffixText: '%',
                helperText: 'Annual interest rate',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter interest rate';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 100) {
                  return 'Please enter a valid rate (0-100)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<InterestType>(
              value: _interestType,
              decoration: const InputDecoration(
                labelText: 'Interest Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: InterestType.fixed,
                  child: Text('Fixed Rate'),
                ),
                DropdownMenuItem(
                  value: InterestType.variable,
                  child: Text('Variable Rate'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _interestType = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentFrequency>(
              value: _paymentFrequency,
              decoration: const InputDecoration(
                labelText: 'Payment Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: PaymentFrequency.monthly,
                  child: Text('Monthly'),
                ),
                DropdownMenuItem(
                  value: PaymentFrequency.quarterly,
                  child: Text('Quarterly'),
                ),
                DropdownMenuItem(
                  value: PaymentFrequency.annually,
                  child: Text('Annually'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _paymentFrequency = value);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Start Date: ${DateFormat('MMMM dd, yyyy').format(_startDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectStartDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_endDate != null
                  ? 'End Date: ${DateFormat('MMMM dd, yyyy').format(_endDate!)}'
                  : 'End Date (Optional)'),
              subtitle: _endDate == null ? const Text('No end date set') : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () => _selectEndDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveLoan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(_isEditing ? 'Update Loan' : 'Add Loan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365 * 10)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 50)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _saveLoan() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(loansNotifierProvider.notifier);

      final loan = Loan(
        id: _isEditing ? widget.loan!.id : const Uuid().v4(),
        propertyId: _selectedPropertyId!,
        lender: _lenderController.text,
        loanType: _loanTypeController.text.isEmpty ? null : _loanTypeController.text,
        originalAmount: double.parse(_originalAmountController.text),
        currentBalance: double.parse(_currentBalanceController.text),
        interestRate: double.parse(_interestRateController.text),
        interestType: _interestType,
        paymentFrequency: _paymentFrequency,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        created: _isEditing ? widget.loan!.created : DateTime.now(),
        updated: DateTime.now(),
      );

      if (_isEditing) {
        await notifier.updateLoan(loan);
      } else {
        await notifier.createLoan(loan);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Loan updated' : 'Loan added')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: const Text('Are you sure you want to delete this loan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notifier = ref.read(loansNotifierProvider.notifier);
              await notifier.deleteLoan(widget.loan!.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan deleted')),
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
