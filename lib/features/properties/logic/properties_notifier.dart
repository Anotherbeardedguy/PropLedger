import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/property.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/property_repository.dart';

class PropertiesNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final PropertyRepository _repository;

  PropertiesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProperties();
  }

  Future<void> loadProperties() async {
    state = const AsyncValue.loading();
    try {
      final properties = await _repository.getAll();
      state = AsyncValue.data(properties);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createProperty(Property property) async {
    try {
      await _repository.create(property);
      await loadProperties();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProperty(Property property) async {
    try {
      await _repository.update(property);
      await loadProperties();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await _repository.delete(id);
      await loadProperties();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadProperties();
  }
}

final propertiesNotifierProvider =
    StateNotifierProvider<PropertiesNotifier, AsyncValue<List<Property>>>((ref) {
  return PropertiesNotifier(ref.watch(propertyRepositoryProvider));
});

final propertyDetailProvider = FutureProvider.family<Property?, String>((ref, id) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return await repository.getById(id);
});
