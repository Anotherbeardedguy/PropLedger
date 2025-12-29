import '../remote/pocketbase_client.dart';
import '../local/database.dart';

abstract class BaseRepository<T> {
  final PocketBaseClient client;
  final AppDatabase database;
  
  BaseRepository({
    required this.client,
    required this.database,
  });

  String get collectionName;

  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<T> create(T entity);
  Future<T> update(T entity);
  Future<void> delete(String id);
  
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
}
