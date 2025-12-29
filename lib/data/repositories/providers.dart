import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../remote/pocketbase_client.dart';
import '../remote/sync_service.dart';
import '../local/database_provider.dart';
import 'auth_repository.dart';
import 'property_repository.dart';
import 'unit_repository.dart';
import 'tenant_repository.dart';
import 'rent_payment_repository.dart';
import 'expense_repository.dart';

final pocketBaseClientProvider = Provider<PocketBaseClient>((ref) {
  return PocketBaseClient();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(pocketBaseClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(
    client: ref.watch(pocketBaseClientProvider),
    database: ref.watch(databaseProvider),
  );
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return UnitRepository(
    client: ref.watch(pocketBaseClientProvider),
    database: ref.watch(databaseProvider),
  );
});

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(
    client: ref.watch(pocketBaseClientProvider),
    database: ref.watch(databaseProvider),
  );
});

final rentPaymentRepositoryProvider = Provider<RentPaymentRepository>((ref) {
  return RentPaymentRepository(
    client: ref.watch(pocketBaseClientProvider),
    database: ref.watch(databaseProvider),
  );
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    client: ref.watch(pocketBaseClientProvider),
    database: ref.watch(databaseProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    propertyRepository: ref.watch(propertyRepositoryProvider),
    unitRepository: ref.watch(unitRepositoryProvider),
    tenantRepository: ref.watch(tenantRepositoryProvider),
    rentPaymentRepository: ref.watch(rentPaymentRepositoryProvider),
    expenseRepository: ref.watch(expenseRepositoryProvider),
  );
});
