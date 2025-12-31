enum TaskPriority { low, medium, high }

enum TaskStatus { open, inProgress, done }

class MaintenanceTask {
  final String id;
  final String propertyId;
  final String? unitId;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final double? cost;
  final String? expenseId;
  final String? attachments;
  final DateTime created;
  final DateTime updated;

  MaintenanceTask({
    required this.id,
    required this.propertyId,
    this.unitId,
    required this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.cost,
    this.expenseId,
    this.attachments,
    required this.created,
    required this.updated,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      unitId: json['unit_id'] as String?,
      description: json['description'] as String,
      priority: _parsePriority(json['priority'] as String),
      status: _parseStatus(json['status'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      expenseId: json['expense_id'] as String?,
      attachments: json['attachments'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'unit_id': unitId,
      'description': description,
      'priority': _priorityToString(priority),
      'status': _statusToString(status),
      'due_date': dueDate?.toIso8601String(),
      'cost': cost,
      'expense_id': expenseId,
      'attachments': attachments,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  static TaskPriority _parsePriority(String priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  static TaskStatus _parseStatus(String status) {
    switch (status) {
      case 'open':
        return TaskStatus.open;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.open;
    }
  }

  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 'open';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.done) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  MaintenanceTask copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    double? cost,
    String? expenseId,
    String? attachments,
    DateTime? created,
    DateTime? updated,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      cost: cost ?? this.cost,
      expenseId: expenseId ?? this.expenseId,
      attachments: attachments ?? this.attachments,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
