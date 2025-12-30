import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/errors/exceptions.dart';

/// Exception for Firebase Storage operations
class StorageException extends AppException {
  StorageException(String message, {String? code})
      : super(message, code: code ?? 'STORAGE_ERROR');
}

/// Firebase service for Firestore, Auth, and Storage operations
class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Auth getters
  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore getters
  FirebaseFirestore get firestore => _firestore;
  
  // Storage getter
  FirebaseStorage get storage => _storage;

  /// Get Firestore collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get Firestore document reference
  DocumentReference<Map<String, dynamic>> doc(String path) {
    return _firestore.doc(path);
  }

  /// Create document with auto-generated ID
  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      return await _firestore.collection(collectionPath).add(data);
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  /// Set document (create or overwrite)
  Future<void> setDocument(
    String documentPath,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      if (!merge) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await _firestore.doc(documentPath).set(
            data,
            SetOptions(merge: merge),
          );
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  /// Update document
  Future<void> updateDocument(
    String documentPath,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.doc(documentPath).update(data);
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  /// Delete document
  Future<void> deleteDocument(String documentPath) async {
    try {
      await _firestore.doc(documentPath).delete();
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  /// Get document snapshot
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String documentPath,
  ) async {
    try {
      return await _firestore.doc(documentPath).get();
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  /// Query collection
  Future<QuerySnapshot<Map<String, dynamic>>> queryCollection(
    String collectionPath, {
    List<QueryFilter>? filters,
    List<QueryOrder>? orderBy,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      if (orderBy != null) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  /// Upload file to Firebase Storage
  Future<String> uploadFile(
    String path,
    String filePath,
  ) async {
    try {
      final ref = _storage.ref(path);
      await ref.putFile(filePath as dynamic);
      return await ref.getDownloadURL();
    } catch (e) {
      throw StorageException('Failed to upload file: ${e.toString()}');
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref(path);
      await ref.delete();
    } catch (e) {
      throw StorageException('Failed to delete file: ${e.toString()}');
    }
  }

  /// Handle Firestore errors
  AppException _handleFirestoreError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return AuthException(
            'Permission denied. Please check your authentication.',
            code: 'PERMISSION_DENIED',
          );
        case 'not-found':
          return AppException(
            'Resource not found.',
            code: 'NOT_FOUND',
          );
        case 'already-exists':
          return ValidationException(
            'Resource already exists.',
            code: 'ALREADY_EXISTS',
          );
        case 'unauthenticated':
          return AuthException(
            'User not authenticated.',
            code: 'UNAUTHENTICATED',
          );
        case 'unavailable':
          return NetworkException(
            'Service temporarily unavailable. Please try again.',
            code: 'UNAVAILABLE',
          );
        default:
          return AppException(
            error.message ?? 'An unexpected error occurred.',
            code: error.code,
          );
      }
    }
    return AppException('An unexpected error occurred: ${error.toString()}');
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Query order helper class
class QueryOrder {
  final String field;
  final bool descending;

  QueryOrder({
    required this.field,
    this.descending = false,
  });
}
