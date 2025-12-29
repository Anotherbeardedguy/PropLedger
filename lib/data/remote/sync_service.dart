import '../repositories/property_repository.dart';
import '../repositories/unit_repository.dart';
import '../repositories/tenant_repository.dart';
import '../repositories/rent_payment_repository.dart';
import '../repositories/expense_repository.dart';
import '../../core/errors/exceptions.dart';

class SyncService {
  final PropertyRepository propertyRepository;
  final UnitRepository unitRepository;
  final TenantRepository tenantRepository;
  final RentPaymentRepository rentPaymentRepository;
  final ExpenseRepository expenseRepository;

  SyncService({
    required this.propertyRepository,
    required this.unitRepository,
    required this.tenantRepository,
    required this.rentPaymentRepository,
    required this.expenseRepository,
  });

  Future<SyncResult> syncAll() async {
    final result = SyncResult();

    try {
      await syncFromRemote();
      result.pullSuccess = true;
    } catch (e) {
      result.pullError = e.toString();
    }

    try {
      await syncToRemote();
      result.pushSuccess = true;
    } catch (e) {
      result.pushError = e.toString();
    }

    result.completedAt = DateTime.now();
    return result;
  }

  Future<void> syncFromRemote() async {
    try {
      await propertyRepository.syncFromRemote();
      await unitRepository.syncFromRemote();
      await tenantRepository.syncFromRemote();
      await rentPaymentRepository.syncFromRemote();
      await expenseRepository.syncFromRemote();
    } catch (e) {
      throw SyncException('Failed to sync from remote: $e');
    }
  }

  Future<void> syncToRemote() async {
    try {
      await propertyRepository.syncToRemote();
      await unitRepository.syncToRemote();
      await tenantRepository.syncToRemote();
      await rentPaymentRepository.syncToRemote();
      await expenseRepository.syncToRemote();
    } catch (e) {
      throw SyncException('Failed to sync to remote: $e');
    }
  }
}

class SyncResult {
  bool pullSuccess = false;
  bool pushSuccess = false;
  String? pullError;
  String? pushError;
  DateTime? completedAt;

  bool get isSuccess => pullSuccess && pushSuccess;
  bool get hasErrors => pullError != null || pushError != null;
}
