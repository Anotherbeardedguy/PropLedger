import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/enhanced_empty_state.dart';
import '../../../core/widgets/enhanced_error_display.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../logic/properties_notifier.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/settings/logic/settings_notifier.dart';
import 'property_detail_screen.dart';
import 'property_form_screen.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text('Properties')
            : TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search properties...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
        actions: [
          if (_searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _searchQuery = ' '; // Trigger search mode
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(propertiesNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return EnhancedEmptyState(
              icon: Icons.home_work,
              title: 'No Properties Yet',
              message: 'Start building your rental portfolio by adding your first property.',
              actionLabel: 'Add Property',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PropertyFormScreen(),
                  ),
                );
              },
            );
          }

          // Apply search filter
          final filteredProperties = properties.where((property) {
            if (_searchQuery.trim().isEmpty) return true;
            final query = _searchQuery.trim().toLowerCase();
            return property.name.toLowerCase().contains(query) ||
                   property.address.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(propertiesNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredProperties.length,
              itemBuilder: (context, index) {
                final property = filteredProperties[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.home_work),
                    ),
                    title: Text(property.name),
                    subtitle: Text(property.address),
                    trailing: property.estimatedValue != null
                        ? Text(
                            CurrencyFormatter.formatCompact(
                              property.estimatedValue!,
                              settings.currency,
                            ),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PropertyDetailScreen(
                            propertyId: property.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const ListSkeleton(itemCount: 5),
        error: (error, _) => EnhancedErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.refresh(propertiesNotifierProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PropertyFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),
    );
  }
}
