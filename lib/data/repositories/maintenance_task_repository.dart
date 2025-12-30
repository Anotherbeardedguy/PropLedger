import 'package:drift/drift.dart';
import '../models/maintenance_task.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class MaintenanceTaskRepository extends BaseRepository<MaintenanceTask> {
  MaintenanceTaskRepository({
    required super.database,
  });

  @override
  Future<List<MaintenanceTask>> getAll() async {
    final entities = await database.select(database.maintenanceTasks).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<MaintenanceTask>> getByPropertyId(String propertyId) async {
    final entities = await (database.select(database.maintenanceTasks)
          ..where((tbl) => tbl.propertyId.equals(propertyId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.created)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<MaintenanceTask>> getByStatus(TaskStatus status) async {
    final entities = await (database.select(database.maintenanceTasks)
          ..where((tbl) => tbl.status.equals(_statusToString(status)))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.dueDate)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<MaintenanceTask>> getOverdueTasks() async {
    final now = DateTime.now();
    final entities = await (database.select(database.maintenanceTasks)
          ..where((tbl) => 
              tbl.dueDate.isSmallerThanValue(now) & 
              tbl.status.isNotValue('done'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.dueDate)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  @override
  Future<MaintenanceTask?> getById(String id) async {
    final entity = await (database.select(database.maintenanceTasks)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<MaintenanceTask> create(MaintenanceTask task) async {
    try {
      await database.into(database.maintenanceTasks).insert(_modelToCompanion(task));
      return task;
    } catch (e) {
      throw DatabaseException('Failed to create maintenance task: $e');
    }
  }

  @override
  Future<MaintenanceTask> update(MaintenanceTask task) async {
    try {
      await database.update(database.maintenanceTasks).replace(_modelToCompanion(task));
      return task;
    } catch (e) {
      throw DatabaseException('Failed to update maintenance task: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.maintenanceTasks)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete maintenance task: $e');
    }
  }

  MaintenanceTask _entityToModel(MaintenanceTaskEntity entity) {
    return MaintenanceTask(
      id: entity.id,
      propertyId: entity.propertyId,
      unitId: entity.unitId,
      description: entity.description,
      priority: _parsePriority(entity.priority),
      status: _parseStatus(entity.status),
      dueDate: entity.dueDate,
      cost: entity.cost,
      attachments: entity.attachments,
      created: entity.created,
      updated: entity.updated,
    );
  }

  MaintenanceTasksCompanion _modelToCompanion(MaintenanceTask task) {
    return MaintenanceTasksCompanion(
      id: Value(task.id),
      propertyId: Value(task.propertyId),
      unitId: Value(task.unitId),
      description: Value(task.description),
      priority: Value(_priorityToString(task.priority)),
      status: Value(_statusToString(task.status)),
      dueDate: Value(task.dueDate),
      cost: Value(task.cost),
      attachments: Value(task.attachments),
      created: Value(task.created),
      updated: Value(task.updated),
    );
  }

  static TaskPriority _parsePriority(String priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  static TaskStatus _parseStatus(String status) {
    switch (status) {
      case 'open':
        return TaskStatus.open;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.open;
    }
  }

  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 'open';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }
}
