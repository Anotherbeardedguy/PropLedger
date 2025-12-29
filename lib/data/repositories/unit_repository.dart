import 'package:drift/drift.dart';
import '../models/unit.dart';
import '../local/database.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class UnitRepository extends BaseRepository<Unit> {
  UnitRepository({
    required super.client,
    required super.database,
  });

  @override
  String get collectionName => ApiConstants.unitsCollection;

  @override
  Future<List<Unit>> getAll() async {
    final entities = await database.select(database.units).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Unit>> getByPropertyId(String propertyId) async {
    final entities = await (database.select(database.units)
          ..where((tbl) => tbl.propertyId.equals(propertyId)))
        .get();
    return entities.map(_entityToModel).toList();
  }

  @override
  Future<Unit?> getById(String id) async {
    final entity = await (database.select(database.units)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<Unit> create(Unit unit) async {
    try {
      await database.into(database.units).insert(
            _modelToCompanion(unit),
          );

      await _queueSync(unit.id, 'create', unit.toJson());

      return unit;
    } catch (e) {
      throw DatabaseException('Failed to create unit: $e');
    }
  }

  @override
  Future<Unit> update(Unit unit) async {
    try {
      await database.update(database.units).replace(
            _modelToCompanion(unit),
          );

      await _queueSync(unit.id, 'update', unit.toJson());

      return unit;
    } catch (e) {
      throw DatabaseException('Failed to update unit: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.units)
            ..where((tbl) => tbl.id.equals(id)))
          .go();

      await _queueSync(id, 'delete', null);
    } catch (e) {
      throw DatabaseException('Failed to delete unit: $e');
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
        final unit = Unit.fromJson(item as Map<String, dynamic>);
        final exists = await getById(unit.id);

        if (exists != null) {
          await database.update(database.units).replace(_modelToCompanion(unit));
        } else {
          await database.into(database.units).insert(_modelToCompanion(unit));
        }
      }
    } catch (e) {
      throw SyncException('Failed to sync units from remote: $e');
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
              await client.post(
                '/collections/$collectionName/records',
                data: {},
              );
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
            await client.delete(
              '/collections/$collectionName/records/${syncItem.recordId}',
            );
            break;
        }

        await database.delete(database.syncQueue).delete(syncItem);
      } catch (e) {
        await database.update(database.syncQueue).replace(
              syncItem.copyWith(
                status: 'failed',
                retryCount: syncItem.retryCount + 1,
              ),
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

  Unit _entityToModel(UnitEntity entity) {
    return Unit(
      id: entity.id,
      propertyId: entity.propertyId,
      unitName: entity.unitName,
      sizeSqm: entity.sizeSqm,
      rooms: entity.rooms,
      rentAmount: entity.rentAmount,
      status: entity.status == 'occupied' ? UnitStatus.occupied : UnitStatus.vacant,
      notes: entity.notes,
      created: entity.created,
      updated: entity.updated,
    );
  }

  UnitsCompanion _modelToCompanion(Unit unit) {
    return UnitsCompanion(
      id: Value(unit.id),
      propertyId: Value(unit.propertyId),
      unitName: Value(unit.unitName),
      sizeSqm: Value(unit.sizeSqm),
      rooms: Value(unit.rooms),
      rentAmount: Value(unit.rentAmount),
      status: Value(unit.status == UnitStatus.occupied ? 'occupied' : 'vacant'),
      notes: Value(unit.notes),
      created: Value(unit.created),
      updated: Value(unit.updated),
    );
  }
}
