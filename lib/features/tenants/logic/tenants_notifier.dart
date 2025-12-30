import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/tenant.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/tenant_repository.dart';
import '../../properties/logic/units_notifier.dart';
import '../../rent_payments/logic/rent_payments_notifier.dart';

class TenantsNotifier extends StateNotifier<AsyncValue<List<Tenant>>> {
  final TenantRepository _repository;
  final String? _unitId;
  final Ref _ref;

  TenantsNotifier(this._repository, this._unitId, this._ref) : super(const AsyncValue.loading()) {
    loadTenants();
  }

  Future<void> loadTenants() async {
    state = const AsyncValue.loading();
    try {
      final tenants = _unitId != null
          ? await _repository.getByUnitId(_unitId)
          : await _repository.getAll();
      state = AsyncValue.data(tenants);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTenant(Tenant tenant) async {
    try {
      await _repository.create(tenant);
      
      // Auto-generate rent payments for the tenant's lease period
      final paymentGenerator = _ref.read(paymentGeneratorServiceProvider);
      await paymentGenerator.generatePaymentsForTenant(tenant);
      
      await loadTenants();
      _ref.invalidate(unitsNotifierProvider);
      // Refresh rent payments to show newly generated payments
      _ref.invalidate(rentPaymentsNotifierProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _repository.update(tenant);
      
      // Regenerate payments if lease dates or terms changed
      final paymentGenerator = _ref.read(paymentGeneratorServiceProvider);
      await paymentGenerator.regeneratePayments(tenant);
      
      await loadTenants();
      _ref.invalidate(unitsNotifierProvider);
      // Refresh rent payments to show regenerated payments
      _ref.invalidate(rentPaymentsNotifierProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      await _repository.delete(id);
      await loadTenants();
      _ref.invalidate(unitsNotifierProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Tenant> getExpiringLeases() {
    return state.maybeWhen(
      data: (tenants) {
        final now = DateTime.now();
        final sixtyDaysFromNow = now.add(const Duration(days: 60));
        return tenants.where((tenant) {
          final leaseEnd = tenant.leaseEnd;
          if (leaseEnd == null) return false;
          return leaseEnd.isAfter(now) && leaseEnd.isBefore(sixtyDaysFromNow);
        }).toList();
      },
      orElse: () => [],
    );
  }
}

final tenantsNotifierProvider = StateNotifierProvider.family<TenantsNotifier, AsyncValue<List<Tenant>>, String?>(
  (ref, unitId) {
    return TenantsNotifier(
      ref.watch(tenantRepositoryProvider),
      unitId,
      ref,
    );
  },
);

final tenantDetailProvider = FutureProvider.family<Tenant?, String>((ref, id) async {
  final repository = ref.watch(tenantRepositoryProvider);
  return repository.getById(id);
});

final expiringLeasesProvider = Provider<List<Tenant>>((ref) {
  final notifier = ref.watch(tenantsNotifierProvider(null).notifier);
  return notifier.getExpiringLeases();
});
