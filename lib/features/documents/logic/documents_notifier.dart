import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/document.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/local/database_provider.dart';

class DocumentsNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  final DocumentRepository _repository;

  DocumentsNotifier(this._repository) : super(const AsyncValue.loading()) {
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

  Future<void> createDocument(Document document) async {
    try {
      await _repository.create(document);
      await loadDocuments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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
      await _repository.delete(id);
      await loadDocuments();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Document> filterByLinkedEntity(LinkedType type, String linkedId) {
    return state.maybeWhen(
      data: (documents) => documents
          .where((d) => d.linkedType == type && d.linkedId == linkedId)
          .toList(),
      orElse: () => [],
    );
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

final documentsNotifierProvider =
    StateNotifierProvider<DocumentsNotifier, AsyncValue<List<Document>>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentsNotifier(repository);
});
