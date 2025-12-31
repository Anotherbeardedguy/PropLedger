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
    // Use junction table to support multi-property loans
    final query = database.select(database.loans).join([
      innerJoin(
        database.loanPropertyLinks,
        database.loanPropertyLinks.loanId.equalsExp(database.loans.id),
      ),
    ])
      ..where(database.loanPropertyLinks.propertyId.equals(propertyId))
      ..orderBy([OrderingTerm.desc(database.loans.created)]);
    
    final results = await query.get();
    return results.map((row) => _entityToModel(row.readTable(database.loans))).toList();
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
      
      // Also create junction table entry for property relationship
      await database.into(database.loanPropertyLinks).insert(
        LoanPropertyLinksCompanion.insert(
          id: 'lpl_${loan.id}_${loan.propertyId}',
          loanId: loan.id,
          propertyId: loan.propertyId,
          created: DateTime.now(),
        ),
      );
      
      return loan;
    } catch (e) {
      throw DatabaseException('Failed to create loan: $e');
    }
  }

  @override
  Future<Loan> update(Loan loan) async {
    try {
      await database.update(database.loans).replace(_modelToCompanion(loan));
      
      // Update junction table: delete old links and create new one
      await (database.delete(database.loanPropertyLinks)
        ..where((tbl) => tbl.loanId.equals(loan.id))).go();
      
      await database.into(database.loanPropertyLinks).insert(
        LoanPropertyLinksCompanion.insert(
          id: 'lpl_${loan.id}_${loan.propertyId}',
          loanId: loan.id,
          propertyId: loan.propertyId,
          created: DateTime.now(),
        ),
      );
      
      return loan;
    } catch (e) {
      throw DatabaseException('Failed to update loan: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      // Delete junction table entries first (foreign key constraint)
      await (database.delete(database.loanPropertyLinks)
        ..where((tbl) => tbl.loanId.equals(id))).go();
      
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
