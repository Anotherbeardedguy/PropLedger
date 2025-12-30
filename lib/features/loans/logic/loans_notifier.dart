import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/loan_payment.dart';
import '../../../data/repositories/loan_repository.dart';
import '../../../data/repositories/loan_payment_repository.dart';
import '../../../data/local/database_provider.dart';

class LoansNotifier extends StateNotifier<AsyncValue<List<Loan>>> {
  final LoanRepository _repository;

  LoansNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLoans();
  }

  Future<void> loadLoans() async {
    state = const AsyncValue.loading();
    try {
      final loans = await _repository.getAll();
      state = AsyncValue.data(loans);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createLoan(Loan loan) async {
    try {
      await _repository.create(loan);
      await loadLoans();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateLoan(Loan loan) async {
    try {
      await _repository.update(loan);
      await loadLoans();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteLoan(String id) async {
    try {
      await _repository.delete(id);
      await loadLoans();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Loan> filterByProperty(String? propertyId) {
    if (propertyId == null) return [];
    return state.maybeWhen(
      data: (loans) => loans.where((l) => l.propertyId == propertyId).toList(),
      orElse: () => [],
    );
  }

  double getTotalLoanBalance() {
    return state.maybeWhen(
      data: (loans) => loans.fold<double>(0.0, (sum, l) => sum + l.currentBalance),
      orElse: () => 0.0,
    );
  }

  double getTotalOriginalAmount() {
    return state.maybeWhen(
      data: (loans) => loans.fold<double>(0.0, (sum, l) => sum + l.originalAmount),
      orElse: () => 0.0,
    );
  }
}

class LoanPaymentsNotifier extends StateNotifier<AsyncValue<List<LoanPayment>>> {
  final LoanPaymentRepository _repository;
  final String? _loanId;

  LoanPaymentsNotifier(this._repository, this._loanId) : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    try {
      final payments = _loanId != null
          ? await _repository.getByLoanId(_loanId)
          : await _repository.getAll();
      state = AsyncValue.data(payments);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createPayment(LoanPayment payment) async {
    try {
      await _repository.create(payment);
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
}

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository(
    database: ref.watch(databaseProvider),
  );
});

final loanPaymentRepositoryProvider = Provider<LoanPaymentRepository>((ref) {
  return LoanPaymentRepository(
    database: ref.watch(databaseProvider),
  );
});

final loansNotifierProvider = StateNotifierProvider<LoansNotifier, AsyncValue<List<Loan>>>((ref) {
  final repository = ref.watch(loanRepositoryProvider);
  return LoansNotifier(repository);
});

final loanPaymentsNotifierProvider = StateNotifierProvider.family<LoanPaymentsNotifier, AsyncValue<List<LoanPayment>>, String?>(
  (ref, loanId) {
    final repository = ref.watch(loanPaymentRepositoryProvider);
    return LoanPaymentsNotifier(repository, loanId);
  },
);
