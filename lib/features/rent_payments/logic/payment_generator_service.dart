import 'package:uuid/uuid.dart';
import '../../../data/models/rent_payment.dart';
import '../../../data/models/tenant.dart';
import '../../../data/repositories/rent_payment_repository.dart';
import '../../../data/repositories/unit_repository.dart';

/// Service to automatically generate rent payments for tenants
/// This implements the "one-time setup" philosophy - payments are generated
/// automatically when tenants are created/updated
class PaymentGeneratorService {
  final RentPaymentRepository _paymentRepository;
  final UnitRepository _unitRepository;

  PaymentGeneratorService({
    required RentPaymentRepository paymentRepository,
    required UnitRepository unitRepository,
  })  : _paymentRepository = paymentRepository,
        _unitRepository = unitRepository;

  /// Generate all rent payments for a tenant's entire lease period
  /// This is called automatically when a tenant is created or lease dates change
  Future<void> generatePaymentsForTenant(Tenant tenant) async {
    // Get unit to determine rent amount
    final unit = await _unitRepository.getById(tenant.unitId);
    if (unit == null) return;

    // Clear existing future payments for this tenant
    await _clearFuturePayments(tenant.id);

    // Only generate if lease dates are set
    if (tenant.leaseStart == null || tenant.leaseEnd == null) return;

    final payments = _calculatePaymentSchedule(
      tenant: tenant,
      rentAmount: unit.rentAmount,
    );

    // Create all payments in database
    for (final payment in payments) {
      await _paymentRepository.create(payment);
    }
  }

  /// Calculate payment schedule based on lease term (monthly/annually)
  List<RentPayment> _calculatePaymentSchedule({
    required Tenant tenant,
    required double rentAmount,
  }) {
    final payments = <RentPayment>[];
    final leaseStart = tenant.leaseStart!;
    final leaseEnd = tenant.leaseEnd!;
    
    DateTime currentDueDate = leaseStart;
    final now = DateTime.now();

    while (currentDueDate.isBefore(leaseEnd) || currentDueDate.isAtSameMomentAs(leaseEnd)) {
      // Determine payment status based on due date
      PaymentStatus status;
      if (currentDueDate.isBefore(now)) {
        // Past due date - mark as late
        status = PaymentStatus.late;
      } else {
        // Future payment - mark as missing (unpaid)
        status = PaymentStatus.missing;
      }

      final payment = RentPayment(
        id: const Uuid().v4(),
        unitId: tenant.unitId,
        tenantId: tenant.id,
        dueDate: currentDueDate,
        paidDate: null,
        amount: rentAmount,
        status: status,
        notes: 'Auto-generated ${tenant.leaseTerm == LeaseTerm.monthly ? "monthly" : "annual"} payment',
        created: now,
        updated: now,
      );

      payments.add(payment);

      // Calculate next due date based on lease term
      if (tenant.leaseTerm == LeaseTerm.monthly) {
        // Add 1 month
        currentDueDate = DateTime(
          currentDueDate.year,
          currentDueDate.month + 1,
          currentDueDate.day,
        );
      } else {
        // Add 1 year
        currentDueDate = DateTime(
          currentDueDate.year + 1,
          currentDueDate.month,
          currentDueDate.day,
        );
      }
    }

    return payments;
  }

  /// Delete all future (unpaid) payments for a tenant
  /// This is called before regenerating payments
  Future<void> _clearFuturePayments(String tenantId) async {
    final allPayments = await _paymentRepository.getAll();
    final tenantPayments = allPayments.where((p) => p.tenantId == tenantId);
    
    for (final payment in tenantPayments) {
      // Only delete unpaid payments (don't touch payment history)
      if (payment.status != PaymentStatus.paid) {
        await _paymentRepository.delete(payment.id);
      }
    }
  }

  /// Regenerate payments when lease dates or rent amount changes
  Future<void> regeneratePayments(Tenant tenant) async {
    await generatePaymentsForTenant(tenant);
  }

  /// Update payment statuses for all tenants (mark overdue payments as late)
  /// This should be called periodically (e.g., on app startup)
  Future<void> updatePaymentStatuses() async {
    final now = DateTime.now();
    final allPayments = await _paymentRepository.getAll();

    for (final payment in allPayments) {
      // Skip already paid payments
      if (payment.status == PaymentStatus.paid) continue;

      // If due date has passed and payment is not marked late, update it
      if (payment.dueDate.isBefore(now) && payment.status != PaymentStatus.late) {
        final updatedPayment = payment.copyWith(
          status: PaymentStatus.late,
          updated: now,
        );
        await _paymentRepository.update(updatedPayment);
      }
    }
  }

  /// Calculate late fee/interest for overdue payment
  /// Default rate: 5% per month (0.1667% per day)
  double calculateLateFee(RentPayment payment, {double annualInterestRate = 0.05}) {
    if (payment.status != PaymentStatus.late || payment.daysOverdue == 0) {
      return 0.0;
    }

    // Simple interest calculation: Principal × Rate × Time
    // Time = days overdue / 365
    final dailyRate = annualInterestRate / 365;
    final lateFee = payment.amount * dailyRate * payment.daysOverdue;
    
    return lateFee;
  }

  /// Get total amount due including late fees
  double getTotalAmountDue(RentPayment payment, {double annualInterestRate = 0.05}) {
    return payment.amount + calculateLateFee(payment, annualInterestRate: annualInterestRate);
  }

  /// Get all upcoming payments (due within next 30 days)
  Future<List<RentPayment>> getUpcomingPayments({int daysAhead = 30}) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));
    
    final allPayments = await _paymentRepository.getAll();
    
    return allPayments.where((payment) {
      // Only unpaid payments
      if (payment.status == PaymentStatus.paid) return false;
      
      // Due date is between now and future date
      return payment.dueDate.isAfter(now) && payment.dueDate.isBefore(futureDate);
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Sort by due date
  }

  /// Get payments that need reminders (due in 3 days)
  Future<List<RentPayment>> getPaymentsNeedingReminders({int daysBefore = 3}) async {
    final now = DateTime.now();
    final reminderDate = now.add(Duration(days: daysBefore));
    
    final allPayments = await _paymentRepository.getAll();
    
    return allPayments.where((payment) {
      if (payment.status == PaymentStatus.paid) return false;
      
      // Due within the next X days
      final dueDate = payment.dueDate;
      return dueDate.isAfter(now) && 
             dueDate.isBefore(reminderDate) &&
             dueDate.difference(now).inDays <= daysBefore;
    }).toList();
  }
}
