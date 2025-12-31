import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense.dart';
import '../logic/expenses_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../properties/logic/units_notifier.dart';

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
  DateTime _selectedDate = DateTime.now();
  bool _recurring = false;

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
      _selectedDate = expense.date;
      _recurring = expense.recurring;
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
                    setState(() => _selectedUnitId = value);
                  },
                ),
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(_isEditing ? 'Update Expense' : 'Add Expense'),
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

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(expensesNotifierProvider.notifier);
      
      final expense = Expense(
        id: _isEditing ? widget.expense!.id : const Uuid().v4(),
        propertyId: _selectedPropertyId!,
        unitId: _selectedUnitId,
        category: _categoryController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        recurring: _recurring,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        receiptFile: _isEditing ? widget.expense!.receiptFile : null,
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
