import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/database_service.dart';

class WebSecurityService {
  static final WebSecurityService instance = WebSecurityService._internal();
  factory WebSecurityService() => instance;
  WebSecurityService._internal();

  // Cache for URL checks to reduce API calls
  final Map<String, UrlSafetyResult> _cache = {};

  /// Check if URL is safe
  /// 
  /// Validates the URL and performs multi-layer security analysis.
  /// 
  /// Throws [ArgumentError] if URL is invalid
  Future<UrlSafetyResult> checkUrl(String url) async {
    // Input validation
    if (url.isEmpty) {
      throw ArgumentError('URL cannot be empty');
    }
    
    if (url.length > 2048) {
      throw ArgumentError('URL too long (max 2048 characters)');
    }
    
    // Sanitize input
    final sanitized = url.trim();
    
    // Validate URL format
    if (!RegExp(r'^https?://').hasMatch(sanitized)) {
      return UrlSafetyResult(
        url: sanitized,
        isSafe: false,
        riskScore: 100,
        threats: ['Invalid URL format - must start with http:// or https://'],
        category: 'Invalid',
      );
    }
    
    // Check cache first
    if (_cache.containsKey(sanitized)) {
      return _cache[sanitized]!;
    }

    try {
      final result = await _performUrlCheck(sanitized);
      
      // Cache result for 1 hour
      _cache[sanitized] = result;
      Future.delayed(const Duration(hours: 1), () => _cache.remove(sanitized));
      
      return result;
    } catch (e) {
      // Return unsafe result on error
      return UrlSafetyResult(
        url: sanitized,
        isSafe: false,
        riskScore: 100,
        threats: ['Error analyzing URL: ${e.toString()}'],
        category: 'Error',
      );
    }
  }

  Future<UrlSafetyResult> _performUrlCheck(String url) async {
    final List<String> threats = [];
    int riskScore = 0;

    // 1. Check domain reputation
    final domainCheck = _checkDomainReputation(url);
    threats.addAll(domainCheck.threats);
    riskScore += domainCheck.score;

    // 2. Check for phishing patterns
    final phishingCheck = _checkPhishingPatterns(url);
    threats.addAll(phishingCheck.threats);
    riskScore += phishingCheck.score;

    // 3. Check SSL/HTTPS
    final sslCheck = _checkSSL(url);
    threats.addAll(sslCheck.threats);
    riskScore += sslCheck.score;

    // 4. Check for typosquatting
    final typoCheck = _checkTyposquatting(url);
    threats.addAll(typoCheck.threats);
    riskScore += typoCheck.score;

    // 5. Check URL structure
    final structureCheck = _checkUrlStructure(url);
    threats.addAll(structureCheck.threats);
    riskScore += structureCheck.score;

    return UrlSafetyResult(
      url: url,
      isSafe: riskScore < 50,
      riskScore: riskScore,
      threats: threats,
      category: _categorizeRisk(riskScore),
    );
  }

  _CheckResult _checkDomainReputation(String url) {
    final threats = <String>[];
    int score = 0;

    try {
      final uri = Uri.parse(url);
      final domain = uri.host;

      // Check against known malicious domains
      final maliciousDomains = [
        'bit.ly', 'tinyurl.com', // URL shorteners (often used in phishing)
      ];

      if (maliciousDomains.any((bad) => domain.contains(bad))) {
        threats.add('Uses URL shortener - may hide malicious links');
        score += 30;
      }

      // Check for suspicious TLDs
      final suspiciousTlds = ['.tk', '.ml', '.ga', '.cf', '.gq'];
      if (suspiciousTlds.any((tld) => domain.endsWith(tld))) {
        threats.add('Uses suspicious free domain extension');
        score += 20;
      }

      // Check for IP address instead of domain
      if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(domain)) {
        threats.add('Uses IP address instead of domain name');
        score += 40;
      }

    } catch (e) {
      threats.add('Invalid URL format');
      score += 50;
    }

    return _CheckResult(threats: threats, score: score);
  }

  _CheckResult _checkPhishingPatterns(String url) {
    final threats = <String>[];
    int score = 0;

    final lowerUrl = url.toLowerCase();

    // Check for phishing keywords
    final phishingKeywords = DatabaseService.instance.getPhishingKeywords();
    int keywordMatches = 0;

    for (final keyword in phishingKeywords) {
      if (lowerUrl.contains(keyword.toLowerCase())) {
        keywordMatches++;
      }
    }

    if (keywordMatches >= 2) {
      threats.add('Contains multiple phishing-related keywords');
      score += 30;
    }

    // Check for login/payment keywords
    final sensitiveKeywords = [
      'login', 'signin', 'verify', 'account', 'update',
      'payment', 'secure', 'bank', 'wallet'
    ];

    if (sensitiveKeywords.any((kw) => lowerUrl.contains(kw))) {
      threats.add('URL targets sensitive operations');
      score += 15;
    }

    // Check for excessive subdomains
    try {
      final uri = Uri.parse(url);
      final parts = uri.host.split('.');
      if (parts.length > 4) {
        threats.add('Suspicious number of subdomains');
        score += 25;
      }
    } catch (e) {
      // Invalid URL
    }

    return _CheckResult(threats: threats, score: score);
  }

  _CheckResult _checkSSL(String url) {
    final threats = <String>[];
    int score = 0;

    if (url.startsWith('http://') && !url.startsWith('https://')) {
      threats.add('No HTTPS encryption - unsafe connection');
      score += 30;
    }

    return _CheckResult(threats: threats, score: score);
  }

  _CheckResult _checkTyposquatting(String url) {
    final threats = <String>[];
    int score = 0;

    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();

      // Popular brands to check against
      final popularBrands = {
        'google': ['goog1e', 'gooogle', 'googIe'],
        'facebook': ['faceb00k', 'faceboook'],
        'amazon': ['amaz0n', 'amazom'],
        'paytm': ['payt m', 'paytmm', 'paytn'],
        'phonepe': ['phonpe', 'phone pe', 'phonepay'],
      };

      for (final brand in popularBrands.entries) {
        for (final typo in brand.value) {
          if (domain.contains(typo)) {
            threats.add('Possible typosquatting of ${brand.key}');
            score += 50;
            break;
          }
        }
      }

      // Check for lookalike characters
      if (domain.contains('1') || domain.contains('0')) {
        final hasLookalike = domain.contains('1') && domain.contains('l') ||
                            domain.contains('0') && domain.contains('o');
        if (hasLookalike) {
          threats.add('Uses confusing characters (0/O or l/1)');
          score += 20;
        }
      }

    } catch (e) {
      // Invalid URL
    }

    return _CheckResult(threats: threats, score: score);
  }

  _CheckResult _checkUrlStructure(String url) {
    final threats = <String>[];
    int score = 0;

    // Check for excessively long URL
    if (url.length > 200) {
      threats.add('Suspiciously long URL');
      score += 15;
    }

    // Check for @ symbol (can hide real domain)
    if (url.contains('@')) {
      threats.add('URL contains @ symbol - may hide real destination');
      score += 40;
    }

    // Check for excessive special characters
    final specialCharCount = url.replaceAll(RegExp(r'[a-zA-Z0-9]'), '').length;
    if (specialCharCount > url.length * 0.3) {
      threats.add('Excessive special characters in URL');
      score += 20;
    }

    return _CheckResult(threats: threats, score: score);
  }

  String _categorizeRisk(int score) {
    if (score >= 70) return 'Critical';
    if (score >= 50) return 'High';
    if (score >= 30) return 'Medium';
    if (score >= 10) return 'Low';
    return 'Safe';
  }

  /// Validate SSL certificate (requires platform implementation)
  Future<bool> validateSslCertificate(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'https') return false;
      
      // This would require native implementation for full cert validation
      // For now, just check if HTTPS
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if domain is on local blacklist
  bool isBlacklisted(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      
      // Check against local blacklist (would be in DatabaseService)
      // For now, return false
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear URL safety cache
  void clearCache() {
    _cache.clear();
  }
}

class _CheckResult {
  final List<String> threats;
  final int score;

  _CheckResult({required this.threats, required this.score});
}

class UrlSafetyResult {
  final String url;
  final bool isSafe;
  final int riskScore;
  final List<String> threats;
  final String category;

  UrlSafetyResult({
    required this.url,
    required this.isSafe,
    required this.riskScore,
    required this.threats,
    required this.category,
  });
}
