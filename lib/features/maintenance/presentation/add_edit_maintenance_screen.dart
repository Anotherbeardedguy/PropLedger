import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../data/models/maintenance_task.dart';
import '../../../data/models/expense.dart';
import '../logic/maintenance_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../properties/logic/units_notifier.dart';
import '../../expenses/logic/expenses_notifier.dart';

class AddEditMaintenanceScreen extends ConsumerStatefulWidget {
  final MaintenanceTask? task;

  const AddEditMaintenanceScreen({super.key, this.task});

  @override
  ConsumerState<AddEditMaintenanceScreen> createState() => _AddEditMaintenanceScreenState();
}

class _AddEditMaintenanceScreenState extends ConsumerState<AddEditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();

  String? _selectedPropertyId;
  String? _selectedUnitId;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.open;
  DateTime? _dueDate;
  bool _createExpense = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.task!;
      _descriptionController.text = task.description;
      _costController.text = task.cost?.toString() ?? '';
      _selectedPropertyId = task.propertyId;
      _selectedUnitId = task.unitId;
      _priority = task.priority;
      _status = task.status;
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
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
        title: Text(_isEditing ? 'Edit Maintenance Task' : 'Add Maintenance Task'),
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
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                helperText: 'What needs to be done?',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
                    const DropdownMenuItem(value: null, child: Text('Property-wide')),
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
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskPriority.low,
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Low'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: TaskPriority.medium,
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Medium'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: TaskPriority.high,
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.red),
                      SizedBox(width: 8),
                      Text('High'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskStatus.open,
                  child: Text('Open'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.inProgress,
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.done,
                  child: Text('Done'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_dueDate != null
                  ? 'Due: ${DateFormat('MMMM dd, yyyy').format(_dueDate!)}'
                  : 'Due Date (Optional)'),
              subtitle: _dueDate == null ? const Text('No due date set') : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () => _selectDueDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost (Optional)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
                helperText: 'Actual or estimated cost',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                // Disable expense creation checkbox if no cost
                if (value.isEmpty && _createExpense) {
                  setState(() => _createExpense = false);
                }
              },
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) {
                    return 'Please enter a valid amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _createExpense,
              onChanged: _costController.text.isEmpty
                  ? null
                  : (value) => setState(() => _createExpense = value ?? false),
              title: const Text('Create expense from this maintenance task'),
              subtitle: Text(
                _costController.text.isEmpty
                    ? 'Enter a cost to enable'
                    : 'Links maintenance task to expense (avoids duplication)',
              ),
              enabled: _costController.text.isNotEmpty,
              secondary: const Icon(Icons.receipt_long),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(_isEditing ? 'Update Task' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final maintenanceNotifier = ref.read(maintenanceNotifierProvider.notifier);
      String? linkedExpenseId;

      // Create expense if checkbox is checked
      if (_createExpense && _costController.text.isNotEmpty) {
        final expensesNotifier = ref.read(expensesNotifierProvider.notifier);
        linkedExpenseId = const Uuid().v4();
        
        final expense = Expense(
          id: linkedExpenseId,
          propertyId: _selectedPropertyId!,
          unitId: _selectedUnitId,
          tenantId: null,
          category: 'Maintenance',
          amount: double.parse(_costController.text),
          date: DateTime.now(),
          recurring: false,
          notes: 'Linked to maintenance task: ${_descriptionController.text}',
          receiptFile: null,
          deductedFromDeposit: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        await expensesNotifier.createExpense(expense);
      }

      final task = MaintenanceTask(
        id: _isEditing ? widget.task!.id : const Uuid().v4(),
        propertyId: _selectedPropertyId!,
        unitId: _selectedUnitId,
        description: _descriptionController.text,
        priority: _priority,
        status: _status,
        dueDate: _dueDate,
        cost: _costController.text.isEmpty ? null : double.parse(_costController.text),
        expenseId: linkedExpenseId ?? (_isEditing ? widget.task!.expenseId : null),
        attachments: _isEditing ? widget.task!.attachments : null,
        created: _isEditing ? widget.task!.created : DateTime.now(),
        updated: DateTime.now(),
      );

      if (_isEditing) {
        await maintenanceNotifier.updateTask(task);
      } else {
        await maintenanceNotifier.createTask(task);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _createExpense
                  ? 'Task and expense created successfully'
                  : _isEditing ? 'Task updated' : 'Task added',
            ),
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this maintenance task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notifier = ref.read(maintenanceNotifierProvider.notifier);
              await notifier.deleteTask(widget.task!.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task deleted')),
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
