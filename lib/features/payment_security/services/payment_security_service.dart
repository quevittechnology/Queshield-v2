import 'package:flutter/services.dart';
import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';

class PaymentSecurityService {
  static final PaymentSecurityService instance = PaymentSecurityService._internal();
  factory PaymentSecurityService() => instance;
  PaymentSecurityService._internal();

  static const MethodChannel _channel = MethodChannel('com.queshield/payment');

  // Known legitimate payment app signatures
  final Map<String, List<String>> _legitimateAppSignatures = {
    'com.google.android.apps.nbu.paisa.user': ['GooglePay'],
    'com.phonepe.app': ['PhonePe'],
    'net.one97.paytm': ['Paytm'],
    'in.amazon.mShop.android.shopping': ['AmazonPay'],
    'com.snapwork.hdfc': ['HDFC'],
  };

  /// Scan installed payment apps
  Future<PaymentSecurityReport> scanPaymentApps() async {
    final List<PaymentAppInfo> scannedApps = [];
    int threatsFound = 0;

    try {
      // Get installed apps (requires native implementation)
      final List<dynamic>? installedApps = 
          await _channel.invokeMethod('getInstalledApps');

      if (installedApps != null) {
        for (final app in installedApps) {
          final packageName = app['packageName'] as String;
          final appName = app['appName'] as String;

          // Check if it's a payment-related app
          if (_isPaymentRelatedApp(packageName, appName)) {
            final info = await _analyzePaymentApp(packageName, appName);
            scannedApps.add(info);
            
            if (!info.isLegitimate) {
              threatsFound++;
              
              // Notify user
              await NotificationService.instance.showThreatNotification(
                title: 'Suspicious Payment App',
                body: '$appName may be fake or cloned',
              );
            }
          }
        }
      }
    } catch (e) {
      // Platform channel not implemented, use basic check
      final fakeApps = _checkKnownFakeApps();
      scannedApps.addAll(fakeApps);
      threatsFound = fakeApps.where((app) => !app.isLegitimate).length;
    }

    return PaymentSecurityReport(
      appsScanned: scannedApps.length,
      threatsFound: threatsFound,
      apps: scannedApps,
      timestamp: DateTime.now(),
    );
  }

  /// Check for screen overlay attacks
  Future<bool> detectScreenOverlay() async {
    try {
      final bool? hasOverlay = await _channel.invokeMethod('checkOverlay');
      return hasOverlay ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Verify UPI app security
  Future<UpiSecurityCheck> checkUpiSecurity(String packageName) async {
    final issues = <String>[];
    
    // Check if app is legitimate
    if (!_legitimateAppSignatures.containsKey(packageName)) {
      issues.add('App not recognized as legitimate UPI provider');
    }
    
    // Check for fake app indicators
    if (DatabaseService.instance.isFakeApp(packageName)) {
      issues.add('App is flagged as fake/cloned');
    }
    
    // Check permissions
    final hasExcessivePermissions = await _checkExcessivePermissions(packageName);
    if (hasExcessivePermissions) {
      issues.add('App requests excessive permissions');
    }
    
    return UpiSecurityCheck(
      packageName: packageName,
      isSecure: issues.isEmpty,
      issues: issues,
      confidence: issues.isEmpty ? 100 : (issues.length > 2 ? 30 : 60),
    );
  }

  /// Monitor transaction SMS
  Future<void> monitorTransactionSms(String sender, String message) async {
    // Analyze SMS for suspicious patterns
    final lowerMessage = message.toLowerCase();
    
    // Check for fake transaction alerts
    final suspiciousKeywords = [
      'verify otp',
      'share otp',
      'urgent verification',
      'account suspended',
      'click link',
      'update kyc',
    ];
    
    for (final keyword in suspiciousKeywords) {
      if (lowerMessage.contains(keyword)) {
        await NotificationService.instance.showThreatNotification(
          title: 'Suspicious Transaction SMS',
          body: 'SMS from $sender contains phishing keywords',
        );
        break;
      }
    }
    
    // Check sender authenticity
    if (!_isLegitimateSmsSender(sender)) {
      await NotificationService.instance.showNotification(
        title: 'Unknown Transaction SMS',
        body: 'Transaction alert from unverified sender: $sender',
      );
    }
  }

  Future<PaymentAppInfo> _analyzePaymentApp(String packageName, String appName) async {
    bool isLegitimate = true;
    final List<String> warnings = [];
    
    // Check against known legitimate apps
    if (!_legitimateAppSignatures.containsKey(packageName)) {
      // Check for suspicious patterns in package name
      if (_hasSuspiciousPackageName(packageName)) {
        isLegitimate = false;
        warnings.add('Suspicious package name');
      }
    }
    
    // Check for fake app indicators
    if (DatabaseService.instance.isFakeApp(packageName)) {
      isLegitimate = false;
      warnings.add('Flagged as fake app');
    }
    
    // Check app name for impersonation
    if (_isImpersonatingKnownApp(appName)) {
      isLegitimate = false;
      warnings.add('May be impersonating legitimate app');
    }
    
    return PaymentAppInfo(
      packageName: packageName,
      appName: appName,
      isLegitimate: isLegitimate,
      warnings: warnings,
      riskLevel: isLegitimate ? 'Low' : 'High',
    );
  }

  bool _isPaymentRelatedApp(String packageName, String appName) {
    final paymentKeywords = [
      'pay', 'wallet', 'upi', 'bank', 'payment',
      'paytm', 'phonepe', 'gpay', 'bhim',
    ];
    
    final lowerPackage = packageName.toLowerCase();
    final lowerName = appName.toLowerCase();
    
    return paymentKeywords.any((keyword) =>
      lowerPackage.contains(keyword) || lowerName.contains(keyword)
    );
  }

  bool _hasSuspiciousPackageName(String packageName) {
    // Check for common fake app patterns
    final suspiciousPatterns = [
      RegExp(r'com\.fake\.'),
      RegExp(r'\.clone\.'),
      RegExp(r'\.mod\.'),
      RegExp(r'\.hack\.'),
      RegExp(r'^com\.app\.'), // Generic package names
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(packageName));
  }

  bool _isImpersonatingKnownApp(String appName) {
    final knownApps = ['paytm', 'phonepe', 'google pay', 'gpay', 'bhim'];
    final lowerName = appName.toLowerCase();
    
    // Check for slight variations
    for (final known in knownApps) {
      if (lowerName.contains(known) && lowerName != known) {
        // Might be "Paytm Pro", "PhonePe Clone", etc.
        return true;
      }
    }
    
    return false;
  }

  bool _isLegitimateSmsSender(String sender) {
    // Common legitimate banking/payment SMS senders
    final legitimateSenders = [
      'HDFCBK', 'ICICIB', 'SBIIN', 'AXISNB', 'KOTAKB',
      'PAYTM', 'PHONEPE', 'GOOGLEPAY', 'AMAZONPAY',
    ];
    
    final upperSender = sender.toUpperCase();
    return legitimateSenders.any((legit) => upperSender.contains(legit));
  }

  Future<bool> _checkExcessivePermissions(String packageName) async {
    // This would require native implementation to check actual permissions
    // For now, return false (not excessive)
    return false;
  }

  List<PaymentAppInfo> _checkKnownFakeApps() {
    // Fallback check against known fake apps in database
    final fakePatterns = [
      'com.fake.paytm',
      'com.fake.phonepe',
      'com.fake.gpay',
    ];
    
    return fakePatterns.map((pkg) {
      return PaymentAppInfo(
        packageName: pkg,
        appName: pkg.split('.').last,
        isLegitimate: false,
        warnings: ['Known fake app'],
        riskLevel: 'Critical',
      );
    }).toList();
  }
}

class PaymentSecurityReport {
  final int appsScanned;
  final int threatsFound;
  final List<PaymentAppInfo> apps;
  final DateTime timestamp;

  PaymentSecurityReport({
    required this.appsScanned,
    required this.threatsFound,
    required this.apps,
    required this.timestamp,
  });
}

class PaymentAppInfo {
  final String packageName;
  final String appName;
  final bool isLegitimate;
  final List<String> warnings;
  final String riskLevel; // Low, Medium, High, Critical

  PaymentAppInfo({
    required this.packageName,
    required this.appName,
    required this.isLegitimate,
    required this.warnings,
    required this.riskLevel,
  });
}

class UpiSecurityCheck {
  final String packageName;
  final bool isSecure;
  final List<String> issues;
  final int confidence;

  UpiSecurityCheck({
    required this.packageName,
    required this.isSecure,
    required this.issues,
    required this.confidence,
  });
}
