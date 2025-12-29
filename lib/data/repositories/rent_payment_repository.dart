import 'package:drift/drift.dart';
import '../models/rent_payment.dart';
import '../local/database.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class RentPaymentRepository extends BaseRepository<RentPayment> {
  RentPaymentRepository({
    required super.client,
    required super.database,
  });

  @override
  String get collectionName => ApiConstants.rentPaymentsCollection;

  @override
  Future<List<RentPayment>> getAll() async {
    final entities = await database.select(database.rentPayments).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<RentPayment>> getByUnitId(String unitId) async {
    final entities = await (database.select(database.rentPayments)
          ..where((tbl) => tbl.unitId.equals(unitId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.dueDate)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<RentPayment>> getOutstandingPayments() async {
    final entities = await (database.select(database.rentPayments)
          ..where((tbl) => tbl.status.isIn(['late', 'missing'])))
        .get();
    return entities.map(_entityToModel).toList();
  }

  @override
  Future<RentPayment?> getById(String id) async {
    final entity = await (database.select(database.rentPayments)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<RentPayment> create(RentPayment payment) async {
    try {
      await database.into(database.rentPayments).insert(_modelToCompanion(payment));
      await _queueSync(payment.id, 'create', payment.toJson());
      return payment;
    } catch (e) {
      throw DatabaseException('Failed to create rent payment: $e');
    }
  }

  @override
  Future<RentPayment> update(RentPayment payment) async {
    try {
      await database.update(database.rentPayments).replace(_modelToCompanion(payment));
      await _queueSync(payment.id, 'update', payment.toJson());
      return payment;
    } catch (e) {
      throw DatabaseException('Failed to update rent payment: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.rentPayments)..where((tbl) => tbl.id.equals(id))).go();
      await _queueSync(id, 'delete', null);
    } catch (e) {
      throw DatabaseException('Failed to delete rent payment: $e');
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
        final payment = RentPayment.fromJson(item as Map<String, dynamic>);
        final exists = await getById(payment.id);

        if (exists != null) {
          await database.update(database.rentPayments).replace(_modelToCompanion(payment));
        } else {
          await database.into(database.rentPayments).insert(_modelToCompanion(payment));
        }
      }
    } catch (e) {
      throw SyncException('Failed to sync rent payments from remote: $e');
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

  RentPayment _entityToModel(RentPaymentEntity entity) {
    return RentPayment(
      id: entity.id,
      unitId: entity.unitId,
      tenantId: entity.tenantId,
      dueDate: entity.dueDate,
      paidDate: entity.paidDate,
      amount: entity.amount,
      status: _parseStatus(entity.status),
      notes: entity.notes,
      created: entity.created,
      updated: entity.updated,
    );
  }

  PaymentStatus _parseStatus(String status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'late':
        return PaymentStatus.late;
      case 'missing':
      default:
        return PaymentStatus.missing;
    }
  }

  RentPaymentsCompanion _modelToCompanion(RentPayment payment) {
    return RentPaymentsCompanion(
      id: Value(payment.id),
      unitId: Value(payment.unitId),
      tenantId: Value(payment.tenantId),
      dueDate: Value(payment.dueDate),
      paidDate: Value(payment.paidDate),
      amount: Value(payment.amount),
      status: Value(_statusToString(payment.status)),
      notes: Value(payment.notes),
      created: Value(payment.created),
      updated: Value(payment.updated),
    );
  }

  String _statusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.late:
        return 'late';
      case PaymentStatus.missing:
        return 'missing';
    }
  }
}
