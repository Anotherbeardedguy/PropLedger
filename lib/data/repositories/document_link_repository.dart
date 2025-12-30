import 'package:drift/drift.dart';
import '../models/document_link.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';

class DocumentLinkRepository {
  final AppDatabase database;

  DocumentLinkRepository({required this.database});

  Future<List<DocumentLink>> getAll() async {
    final entities = await database.select(database.documentLinks).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<DocumentLink>> getByDocumentId(String documentId) async {
    final entities = await (database.select(database.documentLinks)
          ..where((tbl) => tbl.documentId.equals(documentId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.created)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<DocumentLink>> getByLinkedEntity({
    required LinkedType linkedType,
    required String linkedId,
  }) async {
    final entities = await (database.select(database.documentLinks)
          ..where((tbl) =>
              tbl.linkedType.equals(_linkedTypeToString(linkedType)) &
              tbl.linkedId.equals(linkedId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.created)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<DocumentLink?> getById(String id) async {
    final entity = await (database.select(database.documentLinks)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  Future<DocumentLink> create(DocumentLink link) async {
    try {
      await database.into(database.documentLinks).insert(_modelToCompanion(link));
      return link;
    } catch (e) {
      throw DatabaseException('Failed to create document link: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await (database.delete(database.documentLinks)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete document link: $e');
    }
  }

  Future<void> deleteByDocumentId(String documentId) async {
    try {
      await (database.delete(database.documentLinks)
            ..where((tbl) => tbl.documentId.equals(documentId)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete document links: $e');
    }
  }

  DocumentLink _entityToModel(DocumentLinkEntity entity) {
    return DocumentLink(
      id: entity.id,
      documentId: entity.documentId,
      linkedType: _parseLinkedType(entity.linkedType),
      linkedId: entity.linkedId,
      created: entity.created,
    );
  }

  DocumentLinksCompanion _modelToCompanion(DocumentLink link) {
    return DocumentLinksCompanion(
      id: Value(link.id),
      documentId: Value(link.documentId),
      linkedType: Value(_linkedTypeToString(link.linkedType)),
      linkedId: Value(link.linkedId),
      created: Value(link.created),
    );
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
}
