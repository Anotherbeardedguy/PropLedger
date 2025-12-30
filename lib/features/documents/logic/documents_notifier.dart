import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/document.dart';
import '../../../data/models/document_link.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/repositories/document_link_repository.dart';
import '../../../data/local/database_provider.dart';

class DocumentsNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  final DocumentRepository _repository;
  final DocumentLinkRepository _linkRepository;

  DocumentsNotifier(this._repository, this._linkRepository) 
      : super(const AsyncValue.loading()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    try {
      final documents = await _repository.getAll();
      state = AsyncValue.data(documents);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createDocument(Document document, List<DocumentLink> links) async {
    try {
      await _repository.create(document);
      for (final link in links) {
        await _linkRepository.create(link);
      }
      await loadDocuments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<List<DocumentLink>> getLinksForDocument(String documentId) async {
    return await _linkRepository.getByDocumentId(documentId);
  }

  Future<void> updateDocument(Document document) async {
    try {
      await _repository.update(document);
      await loadDocuments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _linkRepository.deleteByDocumentId(id);
      await _repository.delete(id);
      await loadDocuments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  Future<List<Document>> getDocumentsForEntity(LinkedType type, String linkedId) async {
    final links = await _linkRepository.getByLinkedEntity(
      linkedType: type,
      linkedId: linkedId,
    );
    final documentIds = links.map((link) => link.documentId).toSet();
    final allDocuments = await _repository.getAll();
    return allDocuments.where((doc) => documentIds.contains(doc.id)).toList();
  }

  List<Document> getExpiringDocuments({int daysThreshold = 30}) {
    return state.maybeWhen(
      data: (documents) {
        final now = DateTime.now();
        final threshold = now.add(Duration(days: daysThreshold));
        return documents.where((d) {
          if (d.expiryDate == null) return false;
          return d.expiryDate!.isAfter(now) && d.expiryDate!.isBefore(threshold);
        }).toList();
      },
      orElse: () => [],
    );
  }

  List<Document> getExpiredDocuments() {
    return state.maybeWhen(
      data: (documents) {
        final now = DateTime.now();
        return documents.where((d) {
          if (d.expiryDate == null) return false;
          return d.expiryDate!.isBefore(now);
        }).toList();
      },
      orElse: () => [],
    );
  }

  int getExpiringCount() {
    return getExpiringDocuments().length + getExpiredDocuments().length;
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(
    database: ref.watch(databaseProvider),
  );
});

final documentLinkRepositoryProvider = Provider<DocumentLinkRepository>((ref) {
  return DocumentLinkRepository(
    database: ref.watch(databaseProvider),
  );
});

final documentsNotifierProvider =
    StateNotifierProvider<DocumentsNotifier, AsyncValue<List<Document>>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  final linkRepository = ref.watch(documentLinkRepositoryProvider);
  return DocumentsNotifier(repository, linkRepository);
});
