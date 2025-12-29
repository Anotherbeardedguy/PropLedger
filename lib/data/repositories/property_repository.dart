import 'package:drift/drift.dart';
import '../models/property.dart';
import '../local/database.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class PropertyRepository extends BaseRepository<Property> {
  PropertyRepository({
    required super.client,
    required super.database,
  });

  @override
  String get collectionName => ApiConstants.propertiesCollection;

  @override
  Future<List<Property>> getAll() async {
    final entities = await database.select(database.properties).get();
    return entities.map(_entityToModel).toList();
  }

  @override
  Future<Property?> getById(String id) async {
    final entity = await (database.select(database.properties)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<Property> create(Property property) async {
    try {
      await database.into(database.properties).insert(
            _modelToCompanion(property, isUpdate: false),
          );

      await _queueSync(property.id, 'create', property.toJson());

      return property;
    } catch (e) {
      throw DatabaseException('Failed to create property: $e');
    }
  }

  @override
  Future<Property> update(Property property) async {
    try {
      await database.update(database.properties).replace(
            _modelToCompanion(property, isUpdate: true),
          );

      await _queueSync(property.id, 'update', property.toJson());

      return property;
    } catch (e) {
      throw DatabaseException('Failed to update property: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.properties)
            ..where((tbl) => tbl.id.equals(id)))
          .go();

      await _queueSync(id, 'delete', null);
    } catch (e) {
      throw DatabaseException('Failed to delete property: $e');
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
        final property = Property.fromJson(item as Map<String, dynamic>);
        final exists = await getById(property.id);

        if (exists != null) {
          await database.update(database.properties).replace(
                _modelToCompanion(property, isUpdate: true),
              );
        } else {
          await database.into(database.properties).insert(
                _modelToCompanion(property, isUpdate: false),
              );
        }
      }
    } catch (e) {
      throw SyncException('Failed to sync properties from remote: $e');
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
                data: _parsePayload(syncItem.payload!),
              );
            }
            break;
          case 'update':
            if (syncItem.payload != null) {
              await client.patch(
                '/collections/$collectionName/records/${syncItem.recordId}',
                data: _parsePayload(syncItem.payload!),
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

  Property _entityToModel(PropertyEntity entity) {
    return Property(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      purchaseDate: entity.purchaseDate,
      purchasePrice: entity.purchasePrice,
      estimatedValue: entity.estimatedValue,
      notes: entity.notes,
      created: entity.created,
      updated: entity.updated,
    );
  }

  PropertiesCompanion _modelToCompanion(Property property, {required bool isUpdate}) {
    return PropertiesCompanion(
      id: Value(property.id),
      name: Value(property.name),
      address: Value(property.address),
      purchaseDate: Value(property.purchaseDate),
      purchasePrice: Value(property.purchasePrice),
      estimatedValue: Value(property.estimatedValue),
      notes: Value(property.notes),
      created: Value(property.created),
      updated: Value(property.updated),
    );
  }

  Map<String, dynamic> _parsePayload(String payload) {
    return {};
  }
}
