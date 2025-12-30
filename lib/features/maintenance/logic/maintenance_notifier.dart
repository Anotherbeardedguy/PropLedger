import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/maintenance_task.dart';
import '../../../data/repositories/maintenance_task_repository.dart';
import '../../../data/local/database_provider.dart';

class MaintenanceNotifier extends StateNotifier<AsyncValue<List<MaintenanceTask>>> {
  final MaintenanceTaskRepository _repository;

  MaintenanceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getAll();
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTask(MaintenanceTask task) async {
    try {
      await _repository.create(task);
      await loadTasks();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTask(MaintenanceTask task) async {
    try {
      await _repository.update(task);
      await loadTasks();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.delete(id);
      await loadTasks();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<MaintenanceTask> filterByProperty(String? propertyId) {
    if (propertyId == null) return [];
    return state.maybeWhen(
      data: (tasks) => tasks.where((t) => t.propertyId == propertyId).toList(),
      orElse: () => [],
    );
  }

  List<MaintenanceTask> filterByStatus(TaskStatus? status) {
    if (status == null) return [];
    return state.maybeWhen(
      data: (tasks) => tasks.where((t) => t.status == status).toList(),
      orElse: () => [],
    );
  }

  List<MaintenanceTask> filterByPriority(TaskPriority? priority) {
    if (priority == null) return [];
    return state.maybeWhen(
      data: (tasks) => tasks.where((t) => t.priority == priority).toList(),
      orElse: () => [],
    );
  }

  List<MaintenanceTask> getOverdueTasks() {
    return state.maybeWhen(
      data: (tasks) => tasks.where((t) => t.isOverdue).toList(),
      orElse: () => [],
    );
  }

  int getOpenTasksCount() {
    return state.maybeWhen(
      data: (tasks) => tasks.where((t) => t.status != TaskStatus.done).length,
      orElse: () => 0,
    );
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceTaskRepository>((ref) {
  return MaintenanceTaskRepository(
    database: ref.watch(databaseProvider),
  );
});

final maintenanceNotifierProvider =
    StateNotifierProvider<MaintenanceNotifier, AsyncValue<List<MaintenanceTask>>>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return MaintenanceNotifier(repository);
});
