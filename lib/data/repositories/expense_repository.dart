import 'package:drift/drift.dart';
import '../models/expense.dart';
import '../local/database.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository<Expense> {
  ExpenseRepository({
    required super.client,
    required super.database,
  });

  @override
  String get collectionName => ApiConstants.expensesCollection;

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
      await _queueSync(expense.id, 'create', expense.toJson());
      return expense;
    } catch (e) {
      throw DatabaseException('Failed to create expense: $e');
    }
  }

  @override
  Future<Expense> update(Expense expense) async {
    try {
      await database.update(database.expenses).replace(_modelToCompanion(expense));
      await _queueSync(expense.id, 'update', expense.toJson());
      return expense;
    } catch (e) {
      throw DatabaseException('Failed to update expense: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.expenses)..where((tbl) => tbl.id.equals(id))).go();
      await _queueSync(id, 'delete', null);
    } catch (e) {
      throw DatabaseException('Failed to delete expense: $e');
    }
  }

  @override
  Future<void> syncFromRemote() async {
    try {
      final response = await client.get(
        '/collections/$collectionName/records',
        queryParameters: {'perPage': 500},
      );

      final items = response['items'] as List;
      
      for (final item in items) {
        final expense = Expense.fromJson(item as Map<String, dynamic>);
        final exists = await getById(expense.id);

        if (exists != null) {
          await database.update(database.expenses).replace(_modelToCompanion(expense));
        } else {
          await database.into(database.expenses).insert(_modelToCompanion(expense));
        }
      }
    } catch (e) {
      throw SyncException('Failed to sync expenses from remote: $e');
    }
  }

  @override
  Future<void> syncToRemote() async {
    final pendingSync = await (database.select(database.syncQueue)
          ..where((tbl) => tbl.collection.equals(collectionName))
          ..where((tbl) => tbl.status.equals('pending')))
        .get();

    for (final syncItem in pendingSync) {
      try {
        switch (syncItem.operation) {
          case 'create':
            if (syncItem.payload != null) {
              await client.post('/collections/$collectionName/records', data: {});
            }
            break;
          case 'update':
            if (syncItem.payload != null) {
              await client.patch(
                '/collections/$collectionName/records/${syncItem.recordId}',
                data: {},
              );
            }
            break;
          case 'delete':
            await client.delete('/collections/$collectionName/records/${syncItem.recordId}');
            break;
        }

        await database.delete(database.syncQueue).delete(syncItem);
      } catch (e) {
        await database.update(database.syncQueue).replace(
              syncItem.copyWith(status: 'failed', retryCount: syncItem.retryCount + 1),
            );
      }
    }
  }

  Future<void> _queueSync(String recordId, String operation, Map<String, dynamic>? payload) async {
    await database.into(database.syncQueue).insert(
          SyncQueueCompanion.insert(
            collection: collectionName,
            recordId: recordId,
            operation: operation,
            payload: Value(payload?.toString()),
            status: 'pending',
            created: DateTime.now(),
          ),
        );
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
