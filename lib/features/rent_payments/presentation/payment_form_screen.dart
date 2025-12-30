import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/rent_payment.dart';
import '../../tenants/logic/tenants_notifier.dart';
import '../../properties/logic/units_notifier.dart';
import '../logic/rent_payments_notifier.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final RentPayment? payment;

  const PaymentFormScreen({
    super.key,
    this.payment,
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedTenantId;
  String? _selectedUnitId;
  DateTime? _dueDate;
  DateTime? _paidDate;
  PaymentStatus _status = PaymentStatus.missing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      _amountController.text = widget.payment!.amount.toString();
      _notesController.text = widget.payment!.notes ?? '';
      _selectedTenantId = widget.payment!.tenantId;
      _selectedUnitId = widget.payment!.unitId;
      _dueDate = widget.payment!.dueDate;
      _paidDate = widget.payment!.paidDate;
      _status = widget.payment!.status;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isDueDate}) async {
    final initialDate = isDueDate ? (_dueDate ?? DateTime.now()) : (_paidDate ?? DateTime.now());
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _paidDate = picked;
        }
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenantId == null || _selectedUnitId == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final payment = RentPayment(
        id: widget.payment?.id ?? const Uuid().v4(),
        unitId: _selectedUnitId!,
        tenantId: _selectedTenantId!,
        dueDate: _dueDate!,
        paidDate: _paidDate,
        amount: double.parse(_amountController.text),
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        created: widget.payment?.created ?? now,
        updated: now,
      );

      if (widget.payment == null) {
        await ref.read(rentPaymentsNotifierProvider(null).notifier).createPayment(payment);
      } else {
        await ref.read(rentPaymentsNotifierProvider(null).notifier).updatePayment(payment);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.payment == null
                  ? 'Payment recorded successfully'
                  : 'Payment updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));
    final unitsAsync = ref.watch(unitsNotifierProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.payment == null ? 'Record Payment' : 'Edit Payment'),
      ),
      body: tenantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading tenants: $error')),
        data: (tenants) {
          return unitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading units: $error')),
            data: (units) {
              if (tenants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No tenants available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please add tenants first before recording payments',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedTenantId,
                        decoration: const InputDecoration(
                          labelText: 'Tenant',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: tenants.map((tenant) {
                          return DropdownMenuItem(
                            value: tenant.id,
                            child: Text(tenant.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTenantId = value;
                            final tenant = tenants.firstWhere((t) => t.id == value);
                            _selectedUnitId = tenant.unitId;
                            
                            final unit = units.firstWhere((u) => u.id == tenant.unitId);
                            _amountController.text = unit.rentAmount.toString();
                          });
                        },
                        validator: (value) => value == null ? 'Please select a tenant' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedUnitId != null) ...[
                        TextFormField(
                          readOnly: true,
                          initialValue: units.firstWhere((u) => u.id == _selectedUnitId).unitName,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.apartment),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date'),
                        subtitle: Text(
                          _dueDate != null
                              ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                              : 'Not set',
                        ),
                        leading: const Icon(Icons.calendar_today),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _selectDate(context, isDueDate: true),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Payment Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PaymentStatus.paid,
                            child: Text('Paid'),
                          ),
                          DropdownMenuItem(
                            value: PaymentStatus.late,
                            child: Text('Late'),
                          ),
                          DropdownMenuItem(
                            value: PaymentStatus.missing,
                            child: Text('Not Paid'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;
                              if (value == PaymentStatus.paid && _paidDate == null) {
                                _paidDate = DateTime.now();
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_status == PaymentStatus.paid)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Paid Date'),
                          subtitle: Text(
                            _paidDate != null
                                ? DateFormat('MMM dd, yyyy').format(_paidDate!)
                                : 'Not set',
                          ),
                          leading: const Icon(Icons.event_available),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _selectDate(context, isDueDate: false),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      if (_status == PaymentStatus.paid) const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _savePayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                widget.payment == null
                                    ? 'Record Payment'
                                    : 'Update Payment',
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
