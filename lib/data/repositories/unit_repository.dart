import 'package:drift/drift.dart';
import '../models/unit.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class UnitRepository extends BaseRepository<Unit> {
  UnitRepository({
    required super.database,
  });

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
      await database.into(database.units).insert(_modelToCompanion(unit));
      return unit;
    } catch (e) {
      throw DatabaseException('Failed to create unit: $e');
    }
  }

  @override
  Future<Unit> update(Unit unit) async {
    try {
      await database.update(database.units).replace(_modelToCompanion(unit));
      return unit;
    } catch (e) {
      throw DatabaseException('Failed to update unit: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.units)..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException('Failed to delete unit: $e');
    }
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
