class Property {
  final String id;
  final String name;
  final String address;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? estimatedValue;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  Property({
    required this.id,
    required this.name,
    required this.address,
    this.purchaseDate,
    this.purchasePrice,
    this.estimatedValue,
    this.notes,
    required this.created,
    required this.updated,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : null,
      purchasePrice: json['purchase_price'] != null
          ? (json['purchase_price'] as num).toDouble()
          : null,
      estimatedValue: json['estimated_value'] != null
          ? (json['estimated_value'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'estimated_value': estimatedValue,
      'notes': notes,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  Property copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? estimatedValue,
    String? notes,
    DateTime? created,
    DateTime? updated,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
