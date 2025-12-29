import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/unit.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/unit_repository.dart';

class UnitsNotifier extends StateNotifier<AsyncValue<List<Unit>>> {
  final UnitRepository _repository;
  final String? _propertyId;

  UnitsNotifier(this._repository, this._propertyId) : super(const AsyncValue.loading()) {
    loadUnits();
  }

  Future<void> loadUnits() async {
    state = const AsyncValue.loading();
    try {
      final units = _propertyId != null
          ? await _repository.getByPropertyId(_propertyId)
          : await _repository.getAll();
      state = AsyncValue.data(units);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createUnit(Unit unit) async {
    try {
      await _repository.create(unit);
      await loadUnits();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUnit(Unit unit) async {
    try {
      await _repository.update(unit);
      await loadUnits();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteUnit(String id) async {
    try {
      await _repository.delete(id);
      await loadUnits();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadUnits();
  }
}

final unitsNotifierProvider =
    StateNotifierProvider.family<UnitsNotifier, AsyncValue<List<Unit>>, String?>((ref, propertyId) {
  return UnitsNotifier(ref.watch(unitRepositoryProvider), propertyId);
});

final unitDetailProvider = FutureProvider.family<Unit?, String>((ref, id) async {
  final repository = ref.watch(unitRepositoryProvider);
  return await repository.getById(id);
});
