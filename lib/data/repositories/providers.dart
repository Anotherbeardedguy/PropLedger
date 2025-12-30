import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database_provider.dart';
import 'property_repository.dart';
import 'unit_repository.dart';
import 'tenant_repository.dart';

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
