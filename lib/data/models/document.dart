enum LinkedType { property, unit, tenant }

class Document {
  final String id;
  final LinkedType linkedType;
  final String linkedId;
  final String documentType;
  final String file;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  Document({
    required this.id,
    required this.linkedType,
    required this.linkedId,
    required this.documentType,
    required this.file,
    this.expiryDate,
    this.notes,
    required this.created,
    required this.updated,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      linkedType: _parseLinkedType(json['linked_type'] as String),
      linkedId: json['linked_id'] as String,
      documentType: json['document_type'] as String,
      file: json['file'] as String,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      notes: json['notes'] as String?,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'linked_type': _linkedTypeToString(linkedType),
      'linked_id': linkedId,
      'document_type': documentType,
      'file': file,
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  static LinkedType _parseLinkedType(String type) {
    switch (type) {
      case 'unit':
        return LinkedType.unit;
      case 'tenant':
        return LinkedType.tenant;
      case 'property':
      default:
        return LinkedType.property;
    }
  }

  static String _linkedTypeToString(LinkedType type) {
    switch (type) {
      case LinkedType.unit:
        return 'unit';
      case LinkedType.tenant:
        return 'tenant';
      case LinkedType.property:
        return 'property';
    }
  }

  bool get isExpiring {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  Document copyWith({
    String? id,
    LinkedType? linkedType,
    String? linkedId,
    String? documentType,
    String? file,
    DateTime? expiryDate,
    String? notes,
    DateTime? created,
    DateTime? updated,
  }) {
    return Document(
      id: id ?? this.id,
      linkedType: linkedType ?? this.linkedType,
      linkedId: linkedId ?? this.linkedId,
      documentType: documentType ?? this.documentType,
      file: file ?? this.file,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
