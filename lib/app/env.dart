class Env {
  // Firebase configuration is handled by google-services.json
  // No environment variables needed for Firebase
  
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
  
  // Firebase emulator settings (optional, for local development)
  static const bool useFirebaseEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );
  
  static const String firestoreEmulatorHost = String.fromEnvironment(
    'FIRESTORE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );
  
  static const int firestoreEmulatorPort = int.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );
}
