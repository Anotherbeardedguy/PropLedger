import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/models/expense.dart';
import '../logic/expenses_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../properties/logic/units_notifier.dart';
import '../../tenants/logic/tenants_notifier.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPropertyId;
  String? _selectedUnitId;
  String? _selectedTenantId;
  DateTime _selectedDate = DateTime.now();
  bool _recurring = false;
  File? _receiptFile;
  String? _existingReceiptPath;

  bool get _isEditing => widget.expense != null;

  final List<String> _commonCategories = [
    'Repairs & Maintenance',
    'Utilities',
    'Property Tax',
    'Insurance',
    'HOA Fees',
    'Property Management',
    'Cleaning',
    'Landscaping',
    'Legal Fees',
    'Advertising',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final expense = widget.expense!;
      _categoryController.text = expense.category;
      _amountController.text = expense.amount.toString();
      _notesController.text = expense.notes ?? '';
      _selectedPropertyId = expense.propertyId;
      _selectedUnitId = expense.unitId;
      _selectedTenantId = expense.tenantId;
      _selectedDate = expense.date;
      _recurring = expense.recurring;
      _existingReceiptPath = expense.receiptFile;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final unitsAsync = _selectedPropertyId != null
        ? ref.watch(unitsNotifierProvider(_selectedPropertyId!))
        : null;
    final tenantsAsync = _selectedUnitId != null
        ? ref.watch(tenantsNotifierProvider(null))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
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
                  setState(() {
                    _selectedPropertyId = value;
                    _selectedUnitId = null;
                  });
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
            if (unitsAsync != null)
              unitsAsync.when(
                data: (units) => DropdownButtonFormField<String>(
                  value: _selectedUnitId,
                  decoration: const InputDecoration(
                    labelText: 'Unit (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No specific unit')),
                    ...units.map((unit) {
                      return DropdownMenuItem(
                        value: unit.id,
                        child: Text(unit.unitName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUnitId = value;
                      _selectedTenantId = null;
                    });
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
            const SizedBox(height: 16),
            if (_selectedUnitId != null && tenantsAsync != null)
              tenantsAsync.when(
                data: (allTenants) {
                  final unitTenants = allTenants.where((t) => t.unitId == _selectedUnitId).toList();

                  // Ensure selected tenant is valid for this unit
                  if (_selectedTenantId != null && !unitTenants.any((t) => t.id == _selectedTenantId)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedTenantId = null);
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedTenantId,
                    decoration: const InputDecoration(
                      labelText: 'Tenant (Optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Select to enable deposit deduction',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No tenant')),
                      ...unitTenants.map((tenant) {
                        return DropdownMenuItem(
                          value: tenant.id,
                          child: Text('${tenant.name}${tenant.depositAmount != null ? " - Deposit: \$${tenant.depositAmount!.toStringAsFixed(0)}" : ""}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTenantId = value);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _categoryController.text),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _commonCategories;
                }
                return _commonCategories.where((category) {
                  return category.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (selection) {
                _categoryController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                    helperText: 'Type or select a category',
                  ),
                  onChanged: (value) => _categoryController.text = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a category';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                border: OutlineInputBorder(),
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
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring Expense'),
              subtitle: const Text('This expense repeats regularly'),
              value: _recurring,
              onChanged: (value) {
                setState(() => _recurring = value);
              },
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
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 20),
                        const SizedBox(width: 8),
                        const Text('Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_receiptFile != null || _existingReceiptPath != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _receiptFile != null 
                                  ? 'New receipt: ${_receiptFile!.path.split('/').last}'
                                  : 'Receipt attached',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _receiptFile = null;
                                  _existingReceiptPath = null;
                                });
                              },
                              tooltip: 'Remove receipt',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: _pickReceiptFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_receiptFile != null || _existingReceiptPath != null ? 'Change Receipt' : 'Upload Receipt'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(_isEditing ? 'Update Expense' : 'Add Expense'),
            ),
            if (_selectedTenantId != null && tenantsAsync != null)
              tenantsAsync.when(
                data: (allTenants) {
                  final tenant = allTenants.firstWhere((t) => t.id == _selectedTenantId);
                  final hasDeposit = tenant.depositAmount != null && tenant.depositAmount! > 0;
                  final expenseAmount = double.tryParse(_amountController.text) ?? 0;
                  final canDeduct = hasDeposit && expenseAmount > 0 && expenseAmount <= tenant.depositAmount!;
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      onPressed: canDeduct ? () => _deductFromDeposit(tenant) : null,
                      icon: const Icon(Icons.account_balance_wallet),
                      label: Text(
                        canDeduct 
                          ? 'Deduct \$${expenseAmount.toStringAsFixed(2)} from Deposit (\$${tenant.depositAmount!.toStringAsFixed(2)} available)'
                          : !hasDeposit 
                            ? 'No deposit available'
                            : 'Amount exceeds deposit',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        foregroundColor: canDeduct ? Colors.orange : Colors.grey,
                        side: BorderSide(color: canDeduct ? Colors.orange : Colors.grey),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickReceiptFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _receiptFile = File(result.files.single.path!);
        _existingReceiptPath = null;
      });
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(expensesNotifierProvider.notifier);
      
      // Handle receipt file storage path
      String? receiptPath;
      if (_receiptFile != null) {
        // Store file in app documents directory with expense ID
        final expenseId = _isEditing ? widget.expense!.id : const Uuid().v4();
        final fileName = 'receipt_${expenseId}_${DateTime.now().millisecondsSinceEpoch}${_receiptFile!.path.substring(_receiptFile!.path.lastIndexOf('.'))}';
        receiptPath = fileName;
        // TODO: Actual file copy to app directory would happen here in production
      } else if (_existingReceiptPath != null) {
        receiptPath = _existingReceiptPath;
      }
      
      final expense = Expense(
        id: _isEditing ? widget.expense!.id : const Uuid().v4(),
        propertyId: _selectedPropertyId!,
        unitId: _selectedUnitId,
        tenantId: _selectedTenantId,
        category: _categoryController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        recurring: _recurring,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        receiptFile: receiptPath,
        deductedFromDeposit: false,
        created: _isEditing ? widget.expense!.created : DateTime.now(),
        updated: DateTime.now(),
      );

      if (_isEditing) {
        await notifier.updateExpense(expense);
      } else {
        await notifier.createExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Expense updated' : 'Expense added')),
        );
      }
    }
  }

  Future<void> _deductFromDeposit(tenant) async {
    final expenseAmount = double.parse(_amountController.text);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deduct from Deposit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deduct \$${expenseAmount.toStringAsFixed(2)} from ${tenant.name}\'s deposit?'),
            const SizedBox(height: 12),
            Text('Current deposit: \$${tenant.depositAmount!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
            Text('After deduction: \$${(tenant.depositAmount! - expenseAmount).toStringAsFixed(2)}', 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('This will save the expense and update the tenant\'s deposit amount.', 
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deduct from Deposit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Save expense first
      final expensesNotifier = ref.read(expensesNotifierProvider.notifier);
      
      final expense = Expense(
        id: _isEditing ? widget.expense!.id : const Uuid().v4(),
        propertyId: _selectedPropertyId!,
        unitId: _selectedUnitId,
        tenantId: tenant.id,
        category: _categoryController.text,
        amount: expenseAmount,
        date: _selectedDate,
        recurring: _recurring,
        notes: '${_notesController.text.isEmpty ? "" : "${_notesController.text}\n"}[Deducted from ${tenant.name}\'s deposit]',
        receiptFile: _receiptFile != null ? 'receipt_${DateTime.now().millisecondsSinceEpoch}' : _existingReceiptPath,
        deductedFromDeposit: true,
        created: _isEditing ? widget.expense!.created : DateTime.now(),
        updated: DateTime.now(),
      );

      if (_isEditing) {
        await expensesNotifier.updateExpense(expense);
      } else {
        await expensesNotifier.createExpense(expense);
      }

      // Update tenant deposit
      final updatedTenant = tenant.copyWith(
        depositAmount: tenant.depositAmount! - expenseAmount,
        updated: DateTime.now(),
      );
      await ref.read(tenantsNotifierProvider(null).notifier).updateTenant(updatedTenant);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense saved and \$${expenseAmount.toStringAsFixed(2)} deducted from deposit'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notifier = ref.read(expensesNotifierProvider.notifier);
              await notifier.deleteExpense(widget.expense!.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted')),
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
