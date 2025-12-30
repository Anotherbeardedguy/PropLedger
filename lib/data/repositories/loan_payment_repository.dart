import 'package:drift/drift.dart';
import '../models/loan_payment.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class LoanPaymentRepository extends BaseRepository<LoanPayment> {
  LoanPaymentRepository({
    required super.database,
  });

  @override
  Future<List<LoanPayment>> getAll() async {
    final entities = await database.select(database.loanPayments).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<LoanPayment>> getByLoanId(String loanId) async {
    final entities = await (database.select(database.loanPayments)
          ..where((tbl) => tbl.loanId.equals(loanId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.paymentDate)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<double> getTotalPaidForLoan(String loanId) async {
    final entities = await (database.select(database.loanPayments)
          ..where((tbl) => tbl.loanId.equals(loanId)))
        .get();
    return entities.fold<double>(0.0, (sum, e) => sum + e.totalAmount);
  }

  Future<double> getTotalPrincipalPaidForLoan(String loanId) async {
    final entities = await (database.select(database.loanPayments)
          ..where((tbl) => tbl.loanId.equals(loanId)))
        .get();
    return entities.fold<double>(0.0, (sum, e) => sum + e.principalAmount);
  }

  Future<double> getTotalInterestPaidForLoan(String loanId) async {
    final entities = await (database.select(database.loanPayments)
          ..where((tbl) => tbl.loanId.equals(loanId)))
        .get();
    return entities.fold<double>(0.0, (sum, e) => sum + e.interestAmount);
  }

  Future<LoanPayment?> getLatestPaymentForLoan(String loanId) async {
    final entity = await (database.select(database.loanPayments)
          ..where((tbl) => tbl.loanId.equals(loanId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.paymentDate)])
          ..limit(1))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<LoanPayment?> getById(String id) async {
    final entity = await (database.select(database.loanPayments)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<LoanPayment> create(LoanPayment payment) async {
    try {
      await database.into(database.loanPayments).insert(_modelToCompanion(payment));
      return payment;
    } catch (e) {
      throw DatabaseException('Failed to create loan payment: $e');
    }
  }

  @override
  Future<LoanPayment> update(LoanPayment payment) async {
    try {
      await database.update(database.loanPayments).replace(_modelToCompanion(payment));
      return payment;
    } catch (e) {
      throw DatabaseException('Failed to update loan payment: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.loanPayments)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete loan payment: $e');
    }
  }

  LoanPayment _entityToModel(LoanPaymentEntity entity) {
    return LoanPayment(
      id: entity.id,
      loanId: entity.loanId,
      paymentDate: entity.paymentDate,
      totalAmount: entity.totalAmount,
      principalAmount: entity.principalAmount,
      interestAmount: entity.interestAmount,
      remainingBalance: entity.remainingBalance,
      created: entity.created,
      updated: entity.updated,
    );
  }

  LoanPaymentsCompanion _modelToCompanion(LoanPayment payment) {
    return LoanPaymentsCompanion(
      id: Value(payment.id),
      loanId: Value(payment.loanId),
      paymentDate: Value(payment.paymentDate),
      totalAmount: Value(payment.totalAmount),
      principalAmount: Value(payment.principalAmount),
      interestAmount: Value(payment.interestAmount),
      remainingBalance: Value(payment.remainingBalance),
      created: Value(payment.created),
      updated: Value(payment.updated),
    );
  }
}
