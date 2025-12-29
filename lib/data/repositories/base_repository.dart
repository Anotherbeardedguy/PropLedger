import '../local/database.dart';

abstract class BaseRepository<T> {
  final AppDatabase database;
  
  BaseRepository({
    required this.database,
  });

  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<T> create(T entity);
  Future<T> update(T entity);
  Future<void> delete(String id);
}
