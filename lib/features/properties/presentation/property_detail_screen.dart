import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/properties_notifier.dart';
import 'property_form_screen.dart';
import 'widgets/units_tab.dart';
import 'widgets/tenants_tab.dart';
import 'widgets/loans_tab.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/settings/logic/settings_notifier.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyDetailProvider(propertyId));
    final settings = ref.watch(settingsNotifierProvider);

    return propertyAsync.when(
      data: (property) {
        if (property == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Property Not Found')),
            body: const Center(child: Text('Property not found')),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(property.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PropertyFormScreen(property: property),
                      ),
                    );
                  },
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Delete Property'),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Property'),
                            content: const Text(
                              'Are you sure you want to delete this property? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          await ref
                              .read(propertiesNotifierProvider.notifier)
                              .deleteProperty(propertyId);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.apartment), text: 'Units'),
                  Tab(icon: Icon(Icons.people), text: 'Tenants'),
                  Tab(icon: Icon(Icons.attach_money), text: 'Loans'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildInfoTab(context, property, settings),
                UnitsTab(propertyId: propertyId),
                TenantsTab(propertyId: propertyId),
                LoansTab(propertyId: propertyId),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, property, settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow('Name', property.name),
                _buildInfoRow('Address', property.address),
                if (property.purchaseDate != null)
                  _buildInfoRow(
                    'Purchase Date',
                    DateFormatter.format(property.purchaseDate!, settings.dateFormat),
                  ),
                if (property.purchasePrice != null)
                  _buildInfoRow(
                    'Purchase Price',
                    CurrencyFormatter.format(
                      property.purchasePrice!,
                      settings.currency,
                    ),
                  ),
                if (property.estimatedValue != null)
                  _buildInfoRow(
                    'Estimated Value',
                    CurrencyFormatter.format(
                      property.estimatedValue!,
                      settings.currency,
                    ),
                  ),
                if (property.notes != null && property.notes!.isNotEmpty)
                  _buildInfoRow('Notes', property.notes!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
