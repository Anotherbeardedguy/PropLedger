class AppConstants {
  static const String appName = 'PropLedger';
  static const String appVersion = '1.0.0';
  
  static const int syncRetryAttempts = 3;
  static const Duration syncRetryDelay = Duration(seconds: 5);
  
  static const Duration apiTimeout = Duration(seconds: 30);
  
  static const int defaultPageSize = 50;
  static const int maxFileUploadSize = 10 * 1024 * 1024;
}
