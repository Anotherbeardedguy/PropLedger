import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database_provider.dart';
import 'property_repository.dart';
import 'unit_repository.dart';
import 'tenant_repository.dart';
import 'rent_payment_repository.dart';
import 'expense_repository.dart';
import '../../features/rent_payments/logic/payment_generator_service.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(
    database: ref.watch(databaseProvider),
  );
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return UnitRepository(
    database: ref.watch(databaseProvider),
  );
});

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(
    database: ref.watch(databaseProvider),
  );
});

final rentPaymentRepositoryProvider = Provider<RentPaymentRepository>((ref) {
  return RentPaymentRepository(
    database: ref.watch(databaseProvider),
  );
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    database: ref.watch(databaseProvider),
  );
});

final paymentGeneratorServiceProvider = Provider<PaymentGeneratorService>((ref) {
  return PaymentGeneratorService(
    paymentRepository: ref.watch(rentPaymentRepositoryProvider),
    unitRepository: ref.watch(unitRepositoryProvider),
  );
});
