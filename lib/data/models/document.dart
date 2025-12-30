class Document {
  final String id;
  final String documentType;
  final String file;
  final String fileName;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  Document({
    required this.id,
    required this.documentType,
    required this.file,
    required this.fileName,
    this.expiryDate,
    this.notes,
    required this.created,
    required this.updated,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      documentType: json['document_type'] as String,
      file: json['file'] as String,
      fileName: json['file_name'] as String,
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
      'document_type': documentType,
      'file': file,
      'file_name': fileName,
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
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
    String? documentType,
    String? file,
    String? fileName,
    DateTime? expiryDate,
    String? notes,
    DateTime? created,
    DateTime? updated,
  }) {
    return Document(
      id: id ?? this.id,
      documentType: documentType ?? this.documentType,
      file: file ?? this.file,
      fileName: fileName ?? this.fileName,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
