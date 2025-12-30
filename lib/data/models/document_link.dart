enum LinkedType { property, unit, tenant }

class DocumentLink {
  final String id;
  final String documentId;
  final LinkedType linkedType;
  final String linkedId;
  final DateTime created;

  DocumentLink({
    required this.id,
    required this.documentId,
    required this.linkedType,
    required this.linkedId,
    required this.created,
  });

  factory DocumentLink.fromJson(Map<String, dynamic> json) {
    return DocumentLink(
      id: json['id'] as String,
      documentId: json['document_id'] as String,
      linkedType: _parseLinkedType(json['linked_type'] as String),
      linkedId: json['linked_id'] as String,
      created: DateTime.parse(json['created'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'linked_type': _linkedTypeToString(linkedType),
      'linked_id': linkedId,
      'created': created.toIso8601String(),
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

  DocumentLink copyWith({
    String? id,
    String? documentId,
    LinkedType? linkedType,
    String? linkedId,
    DateTime? created,
  }) {
    return DocumentLink(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      linkedType: linkedType ?? this.linkedType,
      linkedId: linkedId ?? this.linkedId,
      created: created ?? this.created,
    );
  }
}
