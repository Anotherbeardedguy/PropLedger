import 'package:drift/drift.dart';
import '../models/loan.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class LoanRepository extends BaseRepository<Loan> {
  LoanRepository({
    required super.database,
  });

  @override
  Future<List<Loan>> getAll() async {
    final entities = await database.select(database.loans).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Loan>> getByPropertyId(String propertyId) async {
    final entities = await (database.select(database.loans)
          ..where((tbl) => tbl.propertyId.equals(propertyId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.created)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<double> getTotalLoanBalance() async {
    final entities = await database.select(database.loans).get();
    return entities.fold<double>(0.0, (sum, e) => sum + e.currentBalance);
  }

  @override
  Future<Loan?> getById(String id) async {
    final entity = await (database.select(database.loans)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<Loan> create(Loan loan) async {
    try {
      await database.into(database.loans).insert(_modelToCompanion(loan));
      return loan;
    } catch (e) {
      throw DatabaseException('Failed to create loan: $e');
    }
  }

  @override
  Future<Loan> update(Loan loan) async {
    try {
      await database.update(database.loans).replace(_modelToCompanion(loan));
      return loan;
    } catch (e) {
      throw DatabaseException('Failed to update loan: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.loans)..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete loan: $e');
    }
  }

  Loan _entityToModel(LoanEntity entity) {
    return Loan(
      id: entity.id,
      propertyId: entity.propertyId ?? '',
      lender: entity.lender,
      loanType: entity.loanType,
      originalAmount: entity.originalAmount,
      currentBalance: entity.currentBalance,
      interestRate: entity.interestRate,
      interestType: _parseInterestType(entity.interestType),
      paymentFrequency: _parsePaymentFrequency(entity.paymentFrequency),
      startDate: entity.startDate,
      endDate: entity.endDate,
      notes: entity.notes,
      created: entity.created,
      updated: entity.updated,
    );
  }

  LoansCompanion _modelToCompanion(Loan loan) {
    return LoansCompanion(
      id: Value(loan.id),
      propertyId: Value(loan.propertyId),
      unitId: const Value(null),
      lender: Value(loan.lender),
      loanType: Value(loan.loanType),
      originalAmount: Value(loan.originalAmount),
      currentBalance: Value(loan.currentBalance),
      interestRate: Value(loan.interestRate),
      interestType: Value(_interestTypeToString(loan.interestType)),
      paymentFrequency: Value(_paymentFrequencyToString(loan.paymentFrequency)),
      startDate: Value(loan.startDate),
      endDate: Value(loan.endDate),
      notes: Value(loan.notes),
      created: Value(loan.created),
      updated: Value(loan.updated),
    );
  }

  static InterestType _parseInterestType(String type) {
    return type == 'variable' ? InterestType.variable : InterestType.fixed;
  }

  static String _interestTypeToString(InterestType type) {
    return type == InterestType.variable ? 'variable' : 'fixed';
  }

  static PaymentFrequency _parsePaymentFrequency(String frequency) {
    switch (frequency) {
      case 'quarterly':
        return PaymentFrequency.quarterly;
      case 'annually':
        return PaymentFrequency.annually;
      case 'monthly':
      default:
        return PaymentFrequency.monthly;
    }
  }

  static String _paymentFrequencyToString(PaymentFrequency frequency) {
    switch (frequency) {
      case PaymentFrequency.quarterly:
        return 'quarterly';
      case PaymentFrequency.annually:
        return 'annually';
      case PaymentFrequency.monthly:
        return 'monthly';
    }
  }
}
