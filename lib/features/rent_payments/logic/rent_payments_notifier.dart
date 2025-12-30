import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/rent_payment.dart';
import '../../../data/repositories/providers.dart';
import '../../../data/repositories/rent_payment_repository.dart';

class RentPaymentsNotifier extends StateNotifier<AsyncValue<List<RentPayment>>> {
  final RentPaymentRepository _repository;
  final String? _unitId;

  RentPaymentsNotifier(this._repository, this._unitId) : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      final payments = _unitId != null
          ? await _repository.getByUnitId(_unitId)
          : await _repository.getAll();
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createPayment(RentPayment payment) async {
    try {
      await _repository.create(payment);
      await loadPayments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePayment(RentPayment payment) async {
    try {
      await _repository.update(payment);
      await loadPayments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await _repository.delete(id);
      await loadPayments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsPaid(String paymentId, DateTime paidDate) async {
    try {
      final payment = await _repository.getById(paymentId);
      if (payment != null) {
        final updatedPayment = payment.copyWith(
          paidDate: paidDate,
          status: PaymentStatus.paid,
          updated: DateTime.now(),
        );
        await _repository.update(updatedPayment);
        await loadPayments();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<RentPayment> getOutstandingPayments() {
    return state.maybeWhen(
      data: (payments) {
        return payments.where((p) => p.status != PaymentStatus.paid).toList();
      },
      orElse: () => [],
    );
  }

  double getTotalOutstanding() {
    return state.maybeWhen(
      data: (payments) {
        return payments
            .where((p) => p.status != PaymentStatus.paid)
            .fold(0.0, (sum, p) => sum + p.amount);
      },
      orElse: () => 0.0,
    );
  }
}

final rentPaymentsNotifierProvider = StateNotifierProvider.family<RentPaymentsNotifier, AsyncValue<List<RentPayment>>, String?>(
  (ref, unitId) {
    return RentPaymentsNotifier(
      ref.watch(rentPaymentRepositoryProvider),
      unitId,
    );
  },
);

final outstandingPaymentsProvider = Provider<List<RentPayment>>((ref) {
  return ref.watch(rentPaymentsNotifierProvider(null).notifier).getOutstandingPayments();
});

final totalOutstandingProvider = Provider<double>((ref) {
  return ref.watch(rentPaymentsNotifierProvider(null).notifier).getTotalOutstanding();
});
