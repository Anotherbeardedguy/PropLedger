import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DataClassName('PropertyEntity')
class Properties extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  RealColumn get purchasePrice => real().nullable()();
  RealColumn get estimatedValue => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UnitEntity')
class Units extends Table {
  TextColumn get id => text()();
  TextColumn get propertyId => text().references(Properties, #id)();
  TextColumn get unitName => text()();
  RealColumn get sizeSqm => real().nullable()();
  IntColumn get rooms => integer().nullable()();
  RealColumn get rentAmount => real()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TenantEntity')
class Tenants extends Table {
  TextColumn get id => text()();
  TextColumn get unitId => text().references(Units, #id)();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get leaseStart => dateTime().nullable()();
  DateTimeColumn get leaseEnd => dateTime().nullable()();
  RealColumn get depositAmount => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RentPaymentEntity')
class RentPayments extends Table {
  TextColumn get id => text()();
  TextColumn get unitId => text().references(Units, #id)();
  TextColumn get tenantId => text().references(Tenants, #id)();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get paidDate => dateTime().nullable()();
  RealColumn get amount => real()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseEntity')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get propertyId => text().references(Properties, #id)();
  TextColumn get unitId => text().nullable().references(Units, #id)();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get recurring => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptFile => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MaintenanceTaskEntity')
class MaintenanceTasks extends Table {
  TextColumn get id => text()();
  TextColumn get propertyId => text().references(Properties, #id)();
  TextColumn get unitId => text().nullable().references(Units, #id)();
  TextColumn get description => text()();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  RealColumn get cost => real().nullable()();
  TextColumn get attachments => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LoanEntity')
class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get propertyId => text().references(Properties, #id)();
  TextColumn get lender => text()();
  TextColumn get loanType => text().nullable()();
  RealColumn get originalAmount => real()();
  RealColumn get currentBalance => real()();
  RealColumn get interestRate => real()();
  TextColumn get interestType => text()();
  TextColumn get paymentFrequency => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LoanPaymentEntity')
class LoanPayments extends Table {
  TextColumn get id => text()();
  TextColumn get loanId => text().references(Loans, #id)();
  DateTimeColumn get paymentDate => dateTime()();
  RealColumn get totalAmount => real()();
  RealColumn get principalAmount => real()();
  RealColumn get interestAmount => real()();
  RealColumn get remainingBalance => real()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DocumentEntity')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get linkedType => text()();
  TextColumn get linkedId => text()();
  TextColumn get documentType => text()();
  TextColumn get file => text()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get created => dateTime()();
  DateTimeColumn get updated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncQueueEntity')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collection => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text().nullable()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get created => dateTime()();
}

@DriftDatabase(
  tables: [
    Properties,
    Units,
    Tenants,
    RentPayments,
    Expenses,
    MaintenanceTasks,
    Loans,
    LoanPayments,
    Documents,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'propledger.db'));
      return NativeDatabase(file);
    });
  }
}
