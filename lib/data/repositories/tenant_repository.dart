import 'package:drift/drift.dart';
import '../models/tenant.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class TenantRepository extends BaseRepository<Tenant> {
  TenantRepository({
    required super.database,
  });

  Future<void> _updateUnitStatus(String unitId, String status) async {
    await (database.update(database.units)
          ..where((tbl) => tbl.id.equals(unitId)))
        .write(UnitsCompanion(
      status: Value(status),
      updated: Value(DateTime.now()),
    ));
  }

  @override
  Future<List<Tenant>> getAll() async {
    final entities = await database.select(database.tenants).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Tenant>> getByUnitId(String unitId) async {
    final entities = await (database.select(database.tenants)
          ..where((tbl) => tbl.unitId.equals(unitId)))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Tenant>> getExpiringLeases({int daysAhead = 60}) async {
    final cutoffDate = DateTime.now().add(Duration(days: daysAhead));
    final entities = await (database.select(database.tenants)
          ..where((tbl) => tbl.leaseEnd.isSmallerOrEqualValue(cutoffDate)))
        .get();
    return entities.map(_entityToModel).toList();
  }

  @override
  Future<Tenant?> getById(String id) async {
    final entity = await (database.select(database.tenants)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<Tenant> create(Tenant tenant) async {
    try {
      await database.into(database.tenants).insert(_modelToCompanion(tenant));
      await _updateUnitStatus(tenant.unitId, 'occupied');
      return tenant;
    } catch (e) {
      throw DatabaseException('Failed to create tenant: $e');
    }
  }

  @override
  Future<Tenant> update(Tenant tenant) async {
    try {
      final oldTenant = await getById(tenant.id);
      await database.update(database.tenants).replace(_modelToCompanion(tenant));
      
      if (oldTenant != null && oldTenant.unitId != tenant.unitId) {
        await _updateUnitStatus(oldTenant.unitId, 'vacant');
        await _updateUnitStatus(tenant.unitId, 'occupied');
      }
      
      return tenant;
    } catch (e) {
      throw DatabaseException('Failed to update tenant: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final tenant = await getById(id);
      await (database.delete(database.tenants)..where((tbl) => tbl.id.equals(id))).go();
      
      if (tenant != null) {
        await _updateUnitStatus(tenant.unitId, 'vacant');
      }
    } catch (e) {
      throw DatabaseException('Failed to delete tenant: $e');
    }
  }

  Tenant _entityToModel(TenantEntity entity) {
    return Tenant(
      id: entity.id,
      unitId: entity.unitId,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      leaseStart: entity.leaseStart,
      leaseEnd: entity.leaseEnd,
      leaseTerm: entity.leaseTerm == 'annually' ? LeaseTerm.annually : LeaseTerm.monthly,
      depositAmount: entity.depositAmount,
      notes: entity.notes,
      created: entity.created,
      updated: entity.updated,
    );
  }

  TenantsCompanion _modelToCompanion(Tenant tenant) {
    return TenantsCompanion(
      id: Value(tenant.id),
      unitId: Value(tenant.unitId),
      name: Value(tenant.name),
      phone: Value(tenant.phone),
      email: Value(tenant.email),
      leaseStart: Value(tenant.leaseStart),
      leaseEnd: Value(tenant.leaseEnd),
      leaseTerm: Value(tenant.leaseTerm == LeaseTerm.annually ? 'annually' : 'monthly'),
      depositAmount: Value(tenant.depositAmount),
      notes: Value(tenant.notes),
      created: Value(tenant.created),
      updated: Value(tenant.updated),
    );
  }
}
