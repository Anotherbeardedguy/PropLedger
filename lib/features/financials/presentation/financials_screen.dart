import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/cashflow_service.dart';
import '../../settings/logic/settings_notifier.dart';
import '../../rent_payments/logic/rent_payments_notifier.dart';
import '../../expenses/logic/expenses_notifier.dart';
import '../../loans/logic/loans_notifier.dart';
import '../../maintenance/logic/maintenance_notifier.dart';
import '../../properties/logic/units_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import '../../tenants/logic/tenants_notifier.dart';
import '../widgets/profit_loss_card.dart';
import '../widgets/cashflow_trend_card.dart';
import '../widgets/property_performance_card.dart';

class FinancialsScreen extends ConsumerStatefulWidget {
  const FinancialsScreen({super.key});

  @override
  ConsumerState<FinancialsScreen> createState() => _FinancialsScreenState();
}

class _FinancialsScreenState extends ConsumerState<FinancialsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(rentPaymentsNotifierProvider(null));
    final expensesAsync = ref.watch(expensesNotifierProvider);
    final loansAsync = ref.watch(loansNotifierProvider);
    final maintenanceAsync = ref.watch(maintenanceNotifierProvider);
    final unitsAsync = ref.watch(unitsNotifierProvider(null));
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final tenantsAsync = ref.watch(tenantsNotifierProvider(null));
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 16),
            paymentsAsync.when(
              data: (payments) {
                return expensesAsync.when(
                  data: (expenses) {
                    return loansAsync.when(
                      data: (loans) {
                        return maintenanceAsync.when(
                          data: (maintenance) {
                            return unitsAsync.when(
                              data: (units) {
                                return propertiesAsync.when(
                                  data: (properties) {
                                    return tenantsAsync.when(
                                      data: (tenants) {
                                        final cashflowService = CashflowService();
                                        final currentMonth = cashflowService.calculateMonthlyCashflow(
                                          rentPayments: payments,
                                          loans: loans,
                                          units: units,
                                          expenses: expenses,
                                          maintenanceTasks: maintenance,
                                        );

                                        return Column(
                                          children: [
                                            ProfitLossCard(
                                              summary: currentMonth,
                                              currency: settings.currency,
                                            ),
                                            const SizedBox(height: 16),
                                            CashflowTrendCard(
                                              cashflowService: cashflowService,
                                              rentPayments: payments,
                                              loans: loans,
                                              units: units,
                                              expenses: expenses,
                                              maintenanceTasks: maintenance,
                                              currency: settings.currency,
                                            ),
                                            const SizedBox(height: 16),
                                            PropertyPerformanceCard(
                                              rentPayments: payments,
                                              expenses: expenses,
                                              loans: loans,
                                              units: units,
                                              tenants: tenants,
                                              properties: properties,
                                              currency: settings.currency,
                                            ),
                                          ],
                                        );
                                      },
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (e, _) => Center(child: Text('Error: $e')),
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (e, _) => Center(child: Text('Error: $e')),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Center(child: Text('Error: $e')),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${DateFormatter.format(_startDate, 'MM/dd/yyyy')} - ${DateFormatter.format(_endDate, 'MM/dd/yyyy')}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: _selectDateRange,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
