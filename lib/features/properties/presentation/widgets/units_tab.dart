import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/units_notifier.dart';
import 'unit_form_dialog.dart';

class UnitsTab extends ConsumerWidget {
  final String propertyId;

  const UnitsTab({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsNotifierProvider(propertyId));

    return unitsAsync.when(
      data: (units) {
        if (units.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apartment,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No units yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add units to this property',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => UnitFormDialog(propertyId: propertyId),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Unit'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                final isVacant = unit.status.toString().contains('vacant');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isVacant ? Colors.orange : Colors.green,
                      child: Icon(
                        isVacant ? Icons.meeting_room : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(unit.unitName),
                    subtitle: Text(
                      '${unit.rooms ?? 0} rooms • \$${unit.rentAmount.toStringAsFixed(0)}/mo',
                    ),
                    trailing: Chip(
                      label: Text(
                        isVacant ? 'Vacant' : 'Occupied',
                        style: TextStyle(
                          color: isVacant ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: isVacant
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => UnitFormDialog(
                          propertyId: propertyId,
                          unit: unit,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => UnitFormDialog(propertyId: propertyId),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
