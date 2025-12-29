import 'package:drift/drift.dart';
import '../models/tenant.dart';
import '../local/database.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class TenantRepository extends BaseRepository<Tenant> {
  TenantRepository({
    required super.client,
    required super.database,
  });

  @override
  String get collectionName => ApiConstants.tenantsCollection;

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
      await _queueSync(tenant.id, 'create', tenant.toJson());
      return tenant;
    } catch (e) {
      throw DatabaseException('Failed to create tenant: $e');
    }
  }

  @override
  Future<Tenant> update(Tenant tenant) async {
    try {
      await database.update(database.tenants).replace(_modelToCompanion(tenant));
      await _queueSync(tenant.id, 'update', tenant.toJson());
      return tenant;
    } catch (e) {
      throw DatabaseException('Failed to update tenant: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.tenants)..where((tbl) => tbl.id.equals(id))).go();
      await _queueSync(id, 'delete', null);
    } catch (e) {
      throw DatabaseException('Failed to delete tenant: $e');
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
        final tenant = Tenant.fromJson(item as Map<String, dynamic>);
        final exists = await getById(tenant.id);

        if (exists != null) {
          await database.update(database.tenants).replace(_modelToCompanion(tenant));
        } else {
          await database.into(database.tenants).insert(_modelToCompanion(tenant));
        }
      }
    } catch (e) {
      throw SyncException('Failed to sync tenants from remote: $e');
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

  Tenant _entityToModel(TenantEntity entity) {
    return Tenant(
      id: entity.id,
      unitId: entity.unitId,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      leaseStart: entity.leaseStart,
      leaseEnd: entity.leaseEnd,
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
      depositAmount: Value(tenant.depositAmount),
      notes: Value(tenant.notes),
      created: Value(tenant.created),
      updated: Value(tenant.updated),
    );
  }
}
