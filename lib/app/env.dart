class Env {
  static const String pocketbaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://localhost:8090',
  );

  static const String pocketbaseApiPath = String.fromEnvironment(
    'POCKETBASE_API_PATH',
    defaultValue: '/api',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
}
