import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/database_service.dart';

class SecurityProvider extends ChangeNotifier {
  int _securityScore = 100;
  int _threatsDetected = 0;
  int _callsBlocked = 0;
  int _scansPerformed = 0;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  List<Map<String, dynamic>> _recentThreats = [];
  
  // Lock for thread-safe updates
  Completer<void> _updateLock = Completer<void>()..complete();
  
  // Getters
  int get securityScore => _securityScore;
  int get threatsDetected => _threatsDetected;
  int get callsBlocked => _callsBlocked;
  int get scansPerformed => _scansPerformed;
  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  List<Map<String, dynamic>> get recentThreats => _recentThreats;
  
  SecurityProvider() {
    _loadSecurityData();
  }
  
  Future<void> _loadSecurityData() async {
    await _performLockedUpdate(() async {
      final db = DatabaseService.instance;
      _threatsDetected = db.getAllThreats().length;
      _callsBlocked = db.getSetting<int>('total_calls_blocked', defaultValue: 0) ?? 0;
      _scansPerformed = db.getScanHistory().length;
      _recentThreats = db.getAllThreats();
      _calculateSecurityScore();
    });
  }
  
  void _calculateSecurityScore() {
    // Security score calculation (100 max)
    int score = 100;
    
    // Deduct points for active threats
    score -= (_threatsDetected * 10).clamp(0, 50);
    
    // Check protection settings
    final db = DatabaseService.instance;
    if (!(db.getSetting<bool>('real_time_protection') ?? false)) score -= 20;
    if (!(db.getSetting<bool>('block_spam_calls') ?? false)) score -= 10;
    if (!(db.getSetting<bool>('web_protection') ?? false)) score -= 10;
    if (!(db.getSetting<bool>('payment_security') ?? false)) score -= 10;
    
    _securityScore = score.clamp(0, 100);
  }
  
  void startScan() {
    _isScanning = true;
    _scanProgress = 0.0;
    notifyListeners();
  }
  
  void updateScanProgress(double progress) {
    _scanProgress = progress;
    notifyListeners();
  }
  
  void completeScan(int threatsFound) {
    _isScanning = false;
    _scanProgress = 1.0;
    _scansPerformed++;
    
    if (threatsFound > 0) {
      _threatsDetected += threatsFound;
      _calculateSecurityScore();
    }
    
    notifyListeners();
  }
  
  Future<void> incrementCallsBlocked() async {
    await _performLockedUpdate(() {
      _callsBlocked++;
      DatabaseService.instance.setSetting('total_calls_blocked', _callsBlocked);
    });
  }
  
  Future<void> removeThreat(String path) async {
    await DatabaseService.instance.removeThreat(path);
    await _loadSecurityData();
  }
  
  Future<void> refreshData() async {
    await _loadSecurityData();
  }

  Future<void> updateSecurityScore(int score) async {
    await _performLockedUpdate(() {
      _securityScore = score.clamp(0, 100);
    });
  }

  Future<void> incrementThreatsDetected() async {
    await _performLockedUpdate(() {
      _threatsDetected++;
      if (_securityScore > 0) {
        _securityScore = (_securityScore - 5).clamp(0, 100);
      }
    });
  }

  Future<void> incrementScansPerformed() async {
    await _performLockedUpdate(() {
      _scansPerformed++;
    });
  }

  Future<void> addThreat(Map<String, dynamic> threat) async {
    await _performLockedUpdate(() {
      _recentThreats.insert(0, threat);
      // Keep only last 10 threats
      if (_recentThreats.length > 10) {
        _recentThreats = _recentThreats.sublist(0, 10);
      }
    });
  }
  
  /// Perform state update with lock to prevent race conditions
  Future<void> _performLockedUpdate(Function() update) async {
    // Wait for previous update to complete
    await _updateLock.future;
    
    // Create new lock for this update
    final completer = Completer<void>();
    _updateLock = completer;
    
    try {
      update();
      notifyListeners();
    } finally {
      completer.complete();
    }
  }
}
```
