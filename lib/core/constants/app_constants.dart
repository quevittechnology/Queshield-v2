/// Application-wide constants
class AppConstants {
  // Scanner Constants
  static const int maxFileSizeBytes = 100 * 1024 * 1024; // 100MB
  static const int maxContentScanSizeBytes = 1 * 1024 * 1024; // 1MB
  static const int quickScanTimeoutSeconds = 30;
  static const int fullScanTimeoutSeconds = 300;
  
  // URL Security Constants
  static const int maxUrlLength = 2048;
  static const int urlCacheDurationHours = 1;
  static const int urlLengthThreshold = 200;
  static const double urlSpecialCharRatio = 0.3;
  
  // Caller ID Constants
  static const int spamConfidenceThreshold = 70;
  static const int minHeuristicScore = 50;
  static const int sequentialDigitThreshold = 5;
  
  // Lost Phone Constants
  static const int minPhoneNumberLength = 10;
  static const int minWipeCodeLength = 6;
  static const int locationUpdateIntervalMinutes = 30;
  static const int alarmMaxDurationMinutes = 2;
  static const int locationTimeoutSeconds = 10;
  
  // Database Constants
  static const int maxCacheSize = 1000;
  static const int recentThreatLimit = 10;
  static const int scanHistoryLimit = 50;
  
  // Notification Constants
  static const String channelIdThreat = 'queshield_threat';
  static const String channelIdScan = 'queshield_scan';
  static const String channelIdGeneral = 'queshield_general';
  
  // Security Constants
  static const String wipeCodeSalt = 'QUESHIELD_WIPE_SALT_V1';
  static const int passwordMinLength = 6;
  static const int maxLoginAttempts = 5;
  
  // Performance Constants
  static const int backgroundSyncIntervalMinutes = 60;
  static const int batteryOptimizationThreshold = 20;
  
  // Risk Score Thresholds
  static const int riskScoreCritical = 70;
  static const int riskScoreHigh = 50;
  static const int riskScoreMedium = 30;
  static const int riskScoreLow = 10;
  
  // Private constructor
  AppConstants._();
}
