import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/loan.dart';
import '../../../data/models/property.dart';
import '../logic/loans_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import 'add_edit_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  String? _selectedPropertyId;

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loansNotifierProvider);
    final propertiesAsync = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: loansAsync.when(
        data: (allLoans) {
          var loans = _selectedPropertyId != null
              ? allLoans.where((l) => l.propertyId == _selectedPropertyId).toList()
              : allLoans;
          
          loans.sort((a, b) => b.created.compareTo(a.created));

          if (loans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No loans found'),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first loan',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final totalBalance = loans.fold<double>(0.0, (sum, l) => sum + l.currentBalance);
          final totalOriginal = loans.fold<double>(0.0, (sum, l) => sum + l.originalAmount);

          return Column(
            children: [
              if (_selectedPropertyId != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Filtered by property',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedPropertyId = null),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Borrowed:'),
                            Text(
                              '\$${totalOriginal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Balance:'),
                            Text(
                              '\$${totalBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Paid:'),
                            Text(
                              '\$${(totalOriginal - totalBalance).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return _buildLoanCard(context, loan, propertiesAsync);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddLoan(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, Loan loan, AsyncValue<List<Property>> propertiesAsync) {
    final property = propertiesAsync.maybeWhen(
      data: (properties) => properties.cast<Property?>().firstWhere(
            (p) => p?.id == loan.propertyId,
            orElse: () => null,
          ),
      orElse: () => null,
    );

    final percentPaid = (loan.totalPaid / loan.originalAmount * 100).clamp(0, 100);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.account_balance, color: Colors.blue.shade700),
        ),
        title: Text(
          loan.lender,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (property != null) Text('Property: ${property.name}'),
            if (loan.loanType != null) Text('Type: ${loan.loanType}'),
            Text('Rate: ${loan.interestRate}% ${loan.interestType == InterestType.fixed ? 'Fixed' : 'Variable'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentPaid / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${percentPaid.toStringAsFixed(0)}%'),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${loan.currentBalance.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            Text(
              'of \$${loan.originalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _navigateToLoanDetail(context, loan),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final propertiesAsync = ref.read(propertiesNotifierProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Loans'),
        content: propertiesAsync.when(
          data: (properties) => DropdownButtonFormField<String>(
            value: _selectedPropertyId,
            decoration: const InputDecoration(labelText: 'Property'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Properties')),
              ...properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
            ],
            onChanged: (value) {
              setState(() => _selectedPropertyId = value);
              Navigator.pop(context);
            },
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error loading properties'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedPropertyId = null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddLoan(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditLoanScreen(),
      ),
    );
  }

  void _navigateToLoanDetail(BuildContext context, Loan loan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanDetailScreen(loan: loan),
      ),
    );
  }
}
