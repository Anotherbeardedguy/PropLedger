import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/maintenance_task.dart';
import '../../../core/widgets/enhanced_empty_state.dart';
import '../../../core/widgets/enhanced_error_display.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../logic/maintenance_notifier.dart';
import '../../properties/logic/properties_notifier.dart';
import 'add_edit_maintenance_screen.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  String? _selectedPropertyId;
  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(maintenanceNotifierProvider);
    final propertiesAsync = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (allTasks) {
          var tasks = _applyFilters(allTasks);
          tasks.sort((a, b) {
            if (a.status != b.status) {
              if (a.status == TaskStatus.open) return -1;
              if (b.status == TaskStatus.open) return 1;
              if (a.status == TaskStatus.inProgress) return -1;
              if (b.status == TaskStatus.inProgress) return 1;
            }
            if (a.dueDate != null && b.dueDate != null) {
              return a.dueDate!.compareTo(b.dueDate!);
            }
            return 0;
          });

          if (tasks.isEmpty) {
            return EnhancedEmptyState(
              icon: Icons.build_circle,
              title: 'No Maintenance Tasks',
              message: 'Keep track of property repairs and maintenance work.',
              actionLabel: 'Add Task',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEditMaintenanceScreen(),
                  ),
                );
              },
            );
          }

          final overdueTasks = tasks.where((t) => t.isOverdue).length;

          return Column(
            children: [
              if (_hasActiveFilters())
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFilterSummary(),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              if (overdueTasks > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '$overdueTasks overdue task${overdueTasks > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(maintenanceNotifierProvider.notifier).loadTasks();
                  },
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(context, task, propertiesAsync);
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const ListSkeleton(itemCount: 5),
        error: (error, _) => EnhancedErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.refresh(maintenanceNotifierProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<MaintenanceTask> _applyFilters(List<MaintenanceTask> tasks) {
    var filtered = tasks;

    if (_selectedPropertyId != null) {
      filtered = filtered.where((t) => t.propertyId == _selectedPropertyId).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((t) => t.status == _selectedStatus).toList();
    }

    if (_selectedPriority != null) {
      filtered = filtered.where((t) => t.priority == _selectedPriority).toList();
    }

    return filtered;
  }

  bool _hasActiveFilters() {
    return _selectedPropertyId != null || _selectedStatus != null || _selectedPriority != null;
  }

  String _getFilterSummary() {
    final parts = <String>[];
    if (_selectedPropertyId != null) parts.add('Property');
    if (_selectedStatus != null) parts.add('Status: ${_getStatusLabel(_selectedStatus!)}');
    if (_selectedPriority != null) parts.add('Priority: ${_getPriorityLabel(_selectedPriority!)}');
    return 'Filters: ${parts.join(', ')}';
  }

  void _clearFilters() {
    setState(() {
      _selectedPropertyId = null;
      _selectedStatus = null;
      _selectedPriority = null;
    });
  }

  Widget _buildTaskCard(BuildContext context, MaintenanceTask task, AsyncValue propertiesAsync) {
    final property = propertiesAsync.maybeWhen(
      data: (properties) => properties.cast<dynamic>().firstWhere(
            (p) => p?.id == task.propertyId,
            orElse: () => null,
          ),
      orElse: () => null,
    );

    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withValues(alpha: 0.2),
          child: Icon(
            task.status == TaskStatus.done ? Icons.check_circle : Icons.build,
            color: priorityColor,
          ),
        ),
        title: Text(
          task.description,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (property != null) Text('Property: ${property.name}'),
            if (task.dueDate != null)
              Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                style: TextStyle(
                  color: task.isOverdue ? Colors.red : null,
                  fontWeight: task.isOverdue ? FontWeight.bold : null,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    _getStatusLabel(task.status),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(
                    _getPriorityLabel(task.priority),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: priorityColor.withValues(alpha: 0.2),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (task.cost != null) ...[
                  const SizedBox(width: 4),
                  Text('\$${task.cost!.toStringAsFixed(2)}'),
                ],
              ],
            ),
          ],
        ),
        trailing: task.isOverdue && task.status != TaskStatus.done
            ? Icon(Icons.warning, color: Colors.red.shade700)
            : null,
        onTap: () => _navigateToEditTask(context, task),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedPropertyId: _selectedPropertyId,
        selectedStatus: _selectedStatus,
        selectedPriority: _selectedPriority,
        onApply: (propertyId, status, priority) {
          setState(() {
            _selectedPropertyId = propertyId;
            _selectedStatus = status;
            _selectedPriority = priority;
          });
        },
      ),
    );
  }

  void _navigateToAddTask(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditMaintenanceScreen(),
      ),
    );
  }

  void _navigateToEditTask(BuildContext context, MaintenanceTask task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMaintenanceScreen(task: task),
      ),
    );
  }
}

class _FilterDialog extends ConsumerStatefulWidget {
  final String? selectedPropertyId;
  final TaskStatus? selectedStatus;
  final TaskPriority? selectedPriority;
  final Function(String?, TaskStatus?, TaskPriority?) onApply;

  const _FilterDialog({
    this.selectedPropertyId,
    this.selectedStatus,
    this.selectedPriority,
    required this.onApply,
  });

  @override
  ConsumerState<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<_FilterDialog> {
  String? _propertyId;
  TaskStatus? _status;
  TaskPriority? _priority;

  @override
  void initState() {
    super.initState();
    _propertyId = widget.selectedPropertyId;
    _status = widget.selectedStatus;
    _priority = widget.selectedPriority;
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesNotifierProvider);

    return AlertDialog(
      title: const Text('Filter Tasks'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            propertiesAsync.when(
              data: (properties) => DropdownButtonFormField<String>(
                value: _propertyId,
                decoration: const InputDecoration(labelText: 'Property'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Properties')),
                  ...properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                ],
                onChanged: (value) => setState(() => _propertyId = value),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading properties'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(value: TaskStatus.open, child: Text('Open')),
                DropdownMenuItem(value: TaskStatus.inProgress, child: Text('In Progress')),
                DropdownMenuItem(value: TaskStatus.done, child: Text('Done')),
              ],
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Priorities')),
                DropdownMenuItem(value: TaskPriority.high, child: Text('High')),
                DropdownMenuItem(value: TaskPriority.medium, child: Text('Medium')),
                DropdownMenuItem(value: TaskPriority.low, child: Text('Low')),
              ],
              onChanged: (value) => setState(() => _priority = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onApply(null, null, null);
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_propertyId, _status, _priority);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
