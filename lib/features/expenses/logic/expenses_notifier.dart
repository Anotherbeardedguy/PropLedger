import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/expense.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/expense_repository.dart';

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;

  ExpensesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getAll();
      state = AsyncValue.data(expenses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createExpense(Expense expense) async {
    try {
      await _repository.create(expense);
      await loadExpenses();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _repository.update(expense);
      await loadExpenses();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repository.delete(id);
      await loadExpenses();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Expense> filterByProperty(String? propertyId) {
    if (propertyId == null) return [];
    return state.maybeWhen(
      data: (expenses) => expenses.where((e) => e.propertyId == propertyId).toList(),
      orElse: () => [],
    );
  }

  List<Expense> filterByCategory(String? category) {
    if (category == null) return [];
    return state.maybeWhen(
      data: (expenses) => expenses.where((e) => e.category == category).toList(),
      orElse: () => [],
    );
  }

  List<Expense> filterByDateRange(DateTime? startDate, DateTime? endDate) {
    return state.maybeWhen(
      data: (expenses) {
        var filtered = expenses;
        if (startDate != null) {
          filtered = filtered.where((e) => e.date.isAfter(startDate) || e.date.isAtSameMomentAs(startDate)).toList();
        }
        if (endDate != null) {
          filtered = filtered.where((e) => e.date.isBefore(endDate) || e.date.isAtSameMomentAs(endDate)).toList();
        }
        return filtered;
      },
      orElse: () => [],
    );
  }

  double getTotalExpenses() {
    return state.maybeWhen(
      data: (expenses) => expenses.fold<double>(0.0, (sum, e) => sum + e.amount),
      orElse: () => 0.0,
    );
  }

  List<String> getCategories() {
    return state.maybeWhen(
      data: (expenses) {
        final categories = expenses.map((e) => e.category).toSet().toList();
        categories.sort();
        return categories;
      },
      orElse: () => [],
    );
  }
}

final expensesNotifierProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpensesNotifier(repository);
});
