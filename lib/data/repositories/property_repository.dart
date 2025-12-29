import 'package:drift/drift.dart';
import '../models/property.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class PropertyRepository extends BaseRepository<Property> {
  PropertyRepository({
    required super.database,
  });

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
    } catch (e) {
      throw DatabaseException('Failed to delete property: $e');
    }
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

}
