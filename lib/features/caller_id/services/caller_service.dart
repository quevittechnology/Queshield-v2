import 'dart:io';
import 'package:flutter/services.dart';
import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';

class CallerService {
  static final CallerService instance = CallerService._internal();
  factory CallerService() => instance;
  CallerService._internal();

  static const MethodChannel _channel = MethodChannel('com.queshield/caller');

  /// Check if a number is spam
  Future<SpamCheckResult> checkNumber(String number) async {
    // Clean number
    final cleanNumber = _cleanPhoneNumber(number);

    // Check local blocked list
    if (DatabaseService.instance.isNumberBlocked(cleanNumber)) {
      return SpamCheckResult(
        isSpam: true,
        confidence: 100,
        source: 'Local Blocklist',
        category: 'Blocked by You',
      );
    }

    // Check against spam patterns
    final spamPatterns = DatabaseService.instance.getSpamPatterns();
    for (final pattern in spamPatterns) {
      final regex = RegExp(pattern);
      if (regex.hasMatch(cleanNumber)) {
        return SpamCheckResult(
          isSpam: true,
          confidence: 85,
          source: 'Pattern Analysis',
          category: 'Suspected Spam',
        );
      }
    }

    // Check common spam number characteristics
    if (_isLikelySpam(cleanNumber)) {
      return SpamCheckResult(
        isSpam: true,
        confidence: 70,
        source: 'Heuristic Analysis',
        category: 'Telemarketing',
      );
    }

    return SpamCheckResult(
      isSpam: false,
      confidence: 0,
      source: 'Clean',
      category: 'Unknown',
    );
  }

  /// Block a number
  Future<void> blockNumber(String number, {String? reason}) async {
    final cleanNumber = _cleanPhoneNumber(number);
    await DatabaseService.instance.blockNumber(
      cleanNumber,
      reason ?? 'Manually blocked',
    );
    
    await NotificationService.instance.showNotification(
      title: 'Number Blocked',
      body: '$cleanNumber has been added to blocklist',
    );
  }

  /// Unblock a number
  Future<void> unblockNumber(String number) async {
    final cleanNumber = _cleanPhoneNumber(number);
    await DatabaseService.instance.unblockNumber(cleanNumber);
    
    await NotificationService.instance.showNotification(
      title: 'Number Unblocked',
      body: '$cleanNumber has been removed from blocklist',
    );
  }

  /// Get blocked numbers
  List<Map<String, dynamic>> getBlockedNumbers() {
    return DatabaseService.instance.getBlockedNumbers();
  }

  /// Handle incoming call (to be called from native code)
  Future<void> handleIncomingCall(String number) async {
    final result = await checkNumber(number);
    
    if (result.isSpam && result.confidence >= 80) {
      // Block the call
      try {
        await _channel.invokeMethod('blockCall', {'number': number});
      } catch (e) {
        // Platform doesn't support automatic blocking
      }
      
      // Show notification
      await NotificationService.instance.showSpamCallNotification(number);
      
      // Increment blocked count
      // This would be called from SecurityProvider
    }
  }

  String _cleanPhoneNumber(String number) {
    // Remove all non-digit characters except +
    return number.replaceAll(RegExp(r'[^\d+]'), '');
  }

  bool _isLikelySpam(String number) {
    // Remove country code for analysis
    String normalized = number.replaceAll(RegExp(r'^\+91'), '');
    
    // Check for telemarketers (140xxxxx in India)
    if (RegExp(r'^140\d{5}$').hasMatch(normalized)) {
      return true;
    }
    
    // Check for sequential numbers (1111111111, 1234567890)
    if (_hasSequentialDigits(normalized, 4)) {
      return true;
    }
    
    // Check for repeated digits
    if (_hasRepeatedDigits(normalized, 5)) {
      return true;
    }
    
    return false;
  }

  bool _hasSequentialDigits(String number, int count) {
    for (int i = 0; i <= number.length - count; i++) {
      bool isSequential = true;
      for (int j = 0; j < count - 1; j++) {
        int current = int.tryParse(number[i + j]) ?? -1;
        int next = int.tryParse(number[i + j + 1]) ?? -1;
        if (current == -1 || next == -1 || next != current + 1) {
          isSequential = false;
          break;
        }
      }
      if (isSequential) return true;
    }
    return false;
  }

  bool _hasRepeatedDigits(String number, int count) {
    for (int i = 0; i <= number.length - count; i++) {
      String char = number[i];
      bool allSame = true;
      for (int j = 1; j < count; j++) {
        if (number[i + j] != char) {
          allSame = false;
          break;
        }
      }
      if (allSame) return true;
    }
    return false;
  }
}

class SpamCheckResult {
  final bool isSpam;
  final int confidence; // 0-100
  final String source;
  final String category;

  SpamCheckResult({
    required this.isSpam,
    required this.confidence,
    required this.source,
    required this.category,
  });
}
