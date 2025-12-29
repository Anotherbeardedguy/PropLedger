import 'package:drift/drift.dart';
import '../models/expense.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository<Expense> {
  ExpenseRepository({
    required super.database,
  });

  @override
  Future<List<Expense>> getAll() async {
    final entities = await database.select(database.expenses).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Expense>> getByPropertyId(String propertyId) async {
    final entities = await (database.select(database.expenses)
          ..where((tbl) => tbl.propertyId.equals(propertyId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<double> getTotalExpenses({
    String? propertyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = database.select(database.expenses);
    
    if (propertyId != null) {
      query = query..where((tbl) => tbl.propertyId.equals(propertyId));
    }
    if (startDate != null) {
      query = query..where((tbl) => tbl.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query = query..where((tbl) => tbl.date.isSmallerOrEqualValue(endDate));
    }

    final entities = await query.get();
    return entities.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Future<Expense?> getById(String id) async {
    final entity = await (database.select(database.expenses)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<Expense> create(Expense expense) async {
    try {
      await database.into(database.expenses).insert(_modelToCompanion(expense));
      return expense;
    } catch (e) {
      throw DatabaseException('Failed to create expense: $e');
    }
  }

  @override
  Future<Expense> update(Expense expense) async {
    try {
      await database.update(database.expenses).replace(_modelToCompanion(expense));
      return expense;
    } catch (e) {
      throw DatabaseException('Failed to update expense: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.expenses)..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete expense: $e');
    }
  }

  Expense _entityToModel(ExpenseEntity entity) {
    return Expense(
      id: entity.id,
      propertyId: entity.propertyId,
      unitId: entity.unitId,
      category: entity.category,
      amount: entity.amount,
      date: entity.date,
      recurring: entity.recurring,
      notes: entity.notes,
      receiptFile: entity.receiptFile,
      created: entity.created,
      updated: entity.updated,
    );
  }

  ExpensesCompanion _modelToCompanion(Expense expense) {
    return ExpensesCompanion(
      id: Value(expense.id),
      propertyId: Value(expense.propertyId),
      unitId: Value(expense.unitId),
      category: Value(expense.category),
      amount: Value(expense.amount),
      date: Value(expense.date),
      recurring: Value(expense.recurring),
      notes: Value(expense.notes),
      receiptFile: Value(expense.receiptFile),
      created: Value(expense.created),
      updated: Value(expense.updated),
    );
  }
}
