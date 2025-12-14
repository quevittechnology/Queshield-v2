import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  // Box names
  static const String settingsBox = 'settings';
  static const String threatsBox = 'threats';
  static const String scanHistoryBox = 'scan_history';
  static const String blockedNumbersBox = 'blocked_numbers';
  static const String quarantineBox = 'quarantine';
  static const String signaturesBox = 'signatures';

  late Box<dynamic> _settingsBox;
  late Box<dynamic> _threatsBox;
  late Box<dynamic> _scanHistoryBox;
  late Box<dynamic> _blockedNumbersBox;
  late Box<dynamic> _quarantineBox;
  late Box<dynamic> _signaturesBox;

  Future<void> init() async {
    // Open all boxes
    _settingsBox = await Hive.openBox(settingsBox);
    _threatsBox = await Hive.openBox(threatsBox);
    _scanHistoryBox = await Hive.openBox(scanHistoryBox);
    _blockedNumbersBox = await Hive.openBox(blockedNumbersBox);
    _quarantineBox = await Hive.openBox(quarantineBox);
    _signaturesBox = await Hive.openBox(signaturesBox);

    // Initialize default settings
    await _initializeDefaults();
    
    // Load threat signatures
    await _loadThreatSignatures();
  }

  Future<void> _initializeDefaults() async {
    if (_settingsBox.isEmpty) {
      await _settingsBox.put('real_time_protection', true);
      await _settingsBox.put('auto_scan', true);
      await _settingsBox.put('scan_schedule', 'daily');
      await _settingsBox.put('block_spam_calls', true);
      await _settingsBox.put('block_spam_sms', true);
      await _settingsBox.put('web_protection', true);
      await _settingsBox.put('payment_security', true);
      await _settingsBox.put('battery_optimization', true);
      await _settingsBox.put('notifications_enabled', true);
      await _settingsBox.put('first_launch', true);
    }
  }

  Future<void> _loadThreatSignatures() async {
    if (_signaturesBox.isEmpty) {
      // Load initial malware signatures (lightweight set)
      final initialSignatures = _getInitialSignatures();
      for (var entry in initialSignatures.entries) {
        await _signaturesBox.put(entry.key, entry.value);
      }
    }
  }

  Map<String, dynamic> _getInitialSignatures() {
    // Lightweight malware signature database
    return {
      // Common malware hashes (MD5)
      'malware_hashes': [
        '44d88612fea8a8f36de82e1278abb02f', // EICAR test file
        'e99a18c428cb38d5f260853678922e03', // Common trojan
      ],
      
      // Suspicious permissions combinations
      'dangerous_permissions': [
        ['READ_SMS', 'SEND_SMS', 'INTERNET'],
        ['READ_CONTACTS', 'ACCESS_FINE_LOCATION', 'INTERNET'],
        ['CAMERA', 'RECORD_AUDIO', 'INTERNET'],
      ],
      
      // Known spam number patterns (India-focused)
      'spam_patterns': [
        r'^140\d{5}$', // Telemarketing
        r'^\+91\s*[789]\d{9}$', // Suspicious mobile
      ],
      
      // Phishing keywords
      'phishing_keywords': [
        'urgent action required',
        'verify your account',
        'claim your prize',
        'digital arrest',
        'cbi officer',
        'income tax notice',
        'courier pending',
        'kyc update',
        'account suspended',
        'verify otp',
      ],
      
      // Fake payment app indicators
      'fake_app_indicators': [
        'com.fake.paytm',
        'com.fake.phonepe',
        'com.fake.gpay',
      ],
    };
  }

  // Settings methods
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  // Threat methods
  Future<void> addThreat(String path, Map<String, dynamic> threatInfo) async {
    await _threatsBox.put(path, {
      ...threatInfo,
      'detected_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeThreat(String path) async {
    await _threatsBox.delete(path);
  }

  List<Map<String, dynamic>> getAllThreats() {
    return _threatsBox.values
        .cast<Map<dynamic, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Scan history methods
  Future<void> addScanRecord(Map<String, dynamic> scanData) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _scanHistoryBox.put(id, scanData);
  }

  List<Map<String, dynamic>> getScanHistory({int limit = 10}) {
    final allScans = _scanHistoryBox.values
        .cast<Map<dynamic, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    
    allScans.sort((a, b) => 
      (b['timestamp'] as int).compareTo(a['timestamp'] as int)
    );
    
    return allScans.take(limit).toList();
  }

  // Blocked numbers methods
  Future<void> blockNumber(String number, String reason) async {
    await _blockedNumbersBox.put(number, {
      'reason': reason,
      'blocked_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unblockNumber(String number) async {
    await _blockedNumbersBox.delete(number);
  }

  bool isNumberBlocked(String number) {
    return _blockedNumbersBox.containsKey(number);
  }

  List<Map<String, dynamic>> getBlockedNumbers() {
    return _blockedNumbersBox.keys.map((key) {
      final value = _blockedNumbersBox.get(key) as Map;
      return {
        'number': key,
        ...Map<String, dynamic>.from(value),
      };
    }).toList();
  }

  // Quarantine methods
  Future<void> quarantineFile(String path, Map<String, dynamic> fileInfo) async {
    await _quarantineBox.put(path, {
      ...fileInfo,
      'quarantined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteQuarantined(String path) async {
    await _quarantineBox.delete(path);
  }

  List<Map<String, dynamic>> getQuarantinedFiles() {
    return _quarantineBox.keys.map((key) {
      final value = _quarantineBox.get(key) as Map;
      return {
        'path': key,
        ...Map<String, dynamic>.from(value),
      };
    }).toList();
  }

  // Signature database methods
  List<String> getMalwareHashes() {
    return (_signaturesBox.get('malware_hashes', defaultValue: []) as List)
        .cast<String>();
  }

  List<String> getPhishingKeywords() {
    return (_signaturesBox.get('phishing_keywords', defaultValue: []) as List)
        .cast<String>();
  }

  List<String> getSpamPatterns() {
    return (_signaturesBox.get('spam_patterns', defaultValue: []) as List)
        .cast<String>();
  }

  bool isFakeApp(String packageName) {
    final fakeApps = (_signaturesBox.get('fake_app_indicators', defaultValue: []) as List)
        .cast<String>();
    return fakeApps.contains(packageName);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _threatsBox.clear();
    await _scanHistoryBox.clear();
    await _quarantineBox.clear();
  }

  // Database size management (for mobile space optimization)
  Future<void> optimizeDatabase() async {
    // Keep only last 30 scan records
    final allScans = _scanHistoryBox.keys.toList();
    if (allScans.length > 30) {
      final toDelete = allScans.take(allScans.length - 30);
      for (var key in toDelete) {
        await _scanHistoryBox.delete(key);
      }
    }

    // Compact Hive boxes
    await _settingsBox.compact();
    await _threatsBox.compact();
    await _scanHistoryBox.compact();
    await _blockedNumbersBox.compact();
    await _quarantineBox.compact();
    await _signaturesBox.compact();
  }
}
