enum UnitStatus { vacant, occupied }

class Unit {
  final String id;
  final String? propertyId;
  final String unitName;
  final double? sizeSqm;
  final int? rooms;
  final double rentAmount;
  final double? upkeepAmount;
  final UnitStatus status;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  Unit({
    required this.id,
    this.propertyId,
    required this.unitName,
    this.sizeSqm,
    this.rooms,
    required this.rentAmount,
    this.upkeepAmount,
    required this.status,
    this.notes,
    required this.created,
    required this.updated,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String,
      propertyId: json['property_id'] as String?,
      unitName: json['unit_name'] as String,
      sizeSqm: json['size_sqm'] != null
          ? (json['size_sqm'] as num).toDouble()
          : null,
      rooms: json['rooms'] as int?,
      rentAmount: (json['rent_amount'] as num).toDouble(),
      upkeepAmount: json['upkeep_amount'] != null
          ? (json['upkeep_amount'] as num).toDouble()
          : null,
      status: _parseStatus(json['status'] as String),
      notes: json['notes'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'unit_name': unitName,
      'size_sqm': sizeSqm,
      'rooms': rooms,
      'rent_amount': rentAmount,
      'upkeep_amount': upkeepAmount,
      'status': _statusToString(status),
      'notes': notes,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  static UnitStatus _parseStatus(String status) {
    return status == 'occupied' ? UnitStatus.occupied : UnitStatus.vacant;
  }

  static String _statusToString(UnitStatus status) {
    return status == UnitStatus.occupied ? 'occupied' : 'vacant';
  }

  Unit copyWith({
    String? id,
    String? propertyId,
    String? unitName,
    double? sizeSqm,
    int? rooms,
    double? rentAmount,
    double? upkeepAmount,
    UnitStatus? status,
    String? notes,
    DateTime? created,
    DateTime? updated,
  }) {
    return Unit(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitName: unitName ?? this.unitName,
      sizeSqm: sizeSqm ?? this.sizeSqm,
      rooms: rooms ?? this.rooms,
      rentAmount: rentAmount ?? this.rentAmount,
      upkeepAmount: upkeepAmount ?? this.upkeepAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
