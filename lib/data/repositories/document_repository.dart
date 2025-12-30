import 'package:drift/drift.dart';
import '../models/document.dart';
import '../local/database.dart';
import '../../core/errors/exceptions.dart';
import 'base_repository.dart';

class DocumentRepository extends BaseRepository<Document> {
  DocumentRepository({
    required super.database,
  });

  @override
  Future<List<Document>> getAll() async {
    final entities = await database.select(database.documents).get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Document>> getExpiringDocuments({int daysAhead = 30}) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));
    
    final entities = await (database.select(database.documents)
          ..where((tbl) =>
              tbl.expiryDate.isBiggerOrEqualValue(now) &
              tbl.expiryDate.isSmallerOrEqualValue(futureDate))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.expiryDate)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Document>> getExpiredDocuments() async {
    final now = DateTime.now();
    
    final entities = await (database.select(database.documents)
          ..where((tbl) => tbl.expiryDate.isSmallerThanValue(now))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.expiryDate)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  Future<List<Document>> getByDocumentType(String documentType) async {
    final entities = await (database.select(database.documents)
          ..where((tbl) => tbl.documentType.equals(documentType))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.created)]))
        .get();
    return entities.map(_entityToModel).toList();
  }

  @override
  Future<Document?> getById(String id) async {
    final entity = await (database.select(database.documents)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  @override
  Future<Document> create(Document document) async {
    try {
      await database.into(database.documents).insert(_modelToCompanion(document));
      return document;
    } catch (e) {
      throw DatabaseException('Failed to create document: $e');
    }
  }

  @override
  Future<Document> update(Document document) async {
    try {
      await database.update(database.documents).replace(_modelToCompanion(document));
      return document;
    } catch (e) {
      throw DatabaseException('Failed to update document: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (database.delete(database.documents)
            ..where((tbl) => tbl.id.equals(id)))
          .go();
    } catch (e) {
      throw DatabaseException('Failed to delete document: $e');
    }
  }

  Document _entityToModel(DocumentEntity entity) {
    return Document(
      id: entity.id,
      documentType: entity.documentType,
      file: entity.file,
      fileName: entity.fileName,
      expiryDate: entity.expiryDate,
      notes: entity.notes,
      created: entity.created,
      updated: entity.updated,
    );
  }

  DocumentsCompanion _modelToCompanion(Document document) {
    return DocumentsCompanion(
      id: Value(document.id),
      documentType: Value(document.documentType),
      file: Value(document.file),
      fileName: Value(document.fileName),
      expiryDate: Value(document.expiryDate),
      notes: Value(document.notes),
      created: Value(document.created),
      updated: Value(document.updated),
    );
  }
}
