import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/expense.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/settings/logic/settings_notifier.dart';
import '../logic/expenses_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import 'add_edit_expense_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _selectedPropertyId;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final propertiesAsync = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (allExpenses) {
          var expenses = _applyFilters(allExpenses);
          expenses.sort((a, b) => b.date.compareTo(a.date));

          if (expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No expenses found'),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first expense',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final totalExpenses = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

          return Column(
            children: [
              if (_hasActiveFilters())
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFilterSummary(),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Expenses:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(totalExpenses, settings.currency),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _buildExpenseCard(context, expense, propertiesAsync);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Expense> _applyFilters(List<Expense> expenses) {
    var filtered = expenses;

    if (_selectedPropertyId != null) {
      filtered = filtered.where((e) => e.propertyId == _selectedPropertyId).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    if (_startDate != null) {
      filtered = filtered.where((e) => e.date.isAfter(_startDate!) || e.date.isAtSameMomentAs(_startDate!)).toList();
    }

    if (_endDate != null) {
      filtered = filtered.where((e) => e.date.isBefore(_endDate!) || e.date.isAtSameMomentAs(_endDate!)).toList();
    }

    return filtered;
  }

  bool _hasActiveFilters() {
    return _selectedPropertyId != null || _selectedCategory != null || _startDate != null || _endDate != null;
  }

  String _getFilterSummary() {
    final parts = <String>[];
    if (_selectedPropertyId != null) parts.add('Property');
    if (_selectedCategory != null) parts.add('Category: $_selectedCategory');
    if (_startDate != null || _endDate != null) parts.add('Date Range');
    return 'Filters: ${parts.join(', ')}';
  }

  void _clearFilters() {
    setState(() {
      _selectedPropertyId = null;
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
    });
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense, AsyncValue propertiesAsync) {
    final property = propertiesAsync.maybeWhen(
      data: (properties) => properties.cast<dynamic>().firstWhere(
            (p) => p?.id == expense.propertyId,
            orElse: () => null,
          ),
      orElse: () => null,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Icon(Icons.receipt, color: Colors.red.shade700),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property != null) Text('Property: ${property.name}'),
            Text(DateFormat('MMM dd, yyyy').format(expense.date)),
            if (expense.notes != null) Text(expense.notes!, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            if (expense.recurring)
              Chip(
                label: const Text('Recurring', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange.shade100,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        onTap: () => _navigateToEditExpense(context, expense),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedPropertyId: _selectedPropertyId,
        selectedCategory: _selectedCategory,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (propertyId, category, start, end) {
          setState(() {
            _selectedPropertyId = propertyId;
            _selectedCategory = category;
            _startDate = start;
            _endDate = end;
          });
        },
      ),
    );
  }

  void _navigateToAddExpense(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditExpenseScreen(),
      ),
    );
  }

  void _navigateToEditExpense(BuildContext context, Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(expense: expense),
      ),
    );
  }
}

class _FilterDialog extends ConsumerStatefulWidget {
  final String? selectedPropertyId;
  final String? selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?, String?, DateTime?, DateTime?) onApply;

  const _FilterDialog({
    this.selectedPropertyId,
    this.selectedCategory,
    this.startDate,
    this.endDate,
    required this.onApply,
  });

  @override
  ConsumerState<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<_FilterDialog> {
  String? _propertyId;
  String? _category;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _propertyId = widget.selectedPropertyId;
    _category = widget.selectedCategory;
    _start = widget.startDate;
    _end = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final expensesNotifier = ref.read(expensesNotifierProvider.notifier);
    final categories = expensesNotifier.getCategories();

    return AlertDialog(
      title: const Text('Filter Expenses'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            propertiesAsync.when(
              data: (properties) => DropdownButtonFormField<String>(
                value: _propertyId,
                decoration: const InputDecoration(labelText: 'Property'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Properties')),
                  ...properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (value) => setState(() => _propertyId = value),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading properties'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_start != null ? 'Start: ${DateFormat('MMM dd, yyyy').format(_start!)}' : 'Start Date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _start ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _start = date);
              },
            ),
            ListTile(
              title: Text(_end != null ? 'End: ${DateFormat('MMM dd, yyyy').format(_end!)}' : 'End Date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _end ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _end = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onApply(null, null, null, null);
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_propertyId, _category, _start, _end);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
