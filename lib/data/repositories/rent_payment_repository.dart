import 'package:drift/drift.dart';
import '../models/rent_payment.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class RentPaymentRepository extends BaseRepository<RentPayment> {
  RentPaymentRepository({
    required super.database,
  });

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
      return payment;
    } catch (e) {
      throw DatabaseException('Failed to create rent payment: $e');
    }
  }

  @override
  Future<RentPayment> update(RentPayment payment) async {
    try {
      await database.update(database.rentPayments).replace(_modelToCompanion(payment));
      return payment;
    } catch (e) {
      throw DatabaseException('Failed to update rent payment: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.rentPayments)..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete rent payment: $e');
    }
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
