import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../remote/pocketbase_client.dart';
import 'auth_repository.dart';

final pocketBaseClientProvider = Provider<PocketBaseClient>((ref) {
  return PocketBaseClient();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(pocketBaseClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
