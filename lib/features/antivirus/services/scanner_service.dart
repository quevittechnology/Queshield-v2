import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/database_service.dart';
import '../../core/services/notification_service.dart';

class ScannerService {
  static final ScannerService instance = ScannerService._internal();
  factory ScannerService() => instance;
  ScannerService._internal();

  bool _isScanning = false;
  int _totalFiles = 0;
  int _scannedFiles = 0;
  int _threatsFound = 0;

  bool get isScanning => _isScanning;
  double get progress => _totalFiles == 0 ? 0 : _scannedFiles / _totalFiles;

  /// Start quick scan (Downloads, Documents)
  Future<ScanResult> quickScan({
    required Function(double) onProgress,
  }) async {
    if (_isScanning) {
      throw Exception('Scan already in progress');
    }

    _isScanning = true;
    _resetCounters();

    try {
      final directories = await _getQuickScanDirectories();
      return await _performScan(directories, onProgress);
    } finally {
      _isScanning = false;
    }
  }

  /// Start full scan (entire storage)
  Future<ScanResult> fullScan({
    required Function(double) onProgress,
  }) async {
    if (_isScanning) {
      throw Exception('Scan already in progress');
    }

    _isScanning = true;
    _resetCounters();

    try {
      final directories = await _getFullScanDirectories();
      return await _performScan(directories, onProgress);
    } finally {
      _isScanning = false;
    }
  }

  /// Scan specific file or directory
  Future<ScanResult> customScan({
    required String path,
    required Function(double) onProgress,
  }) async {
    if (_isScanning) {
      throw Exception('Scan already in progress');
    }

    _isScanning = true;
    _resetCounters();

    try {
      return await _performScan([path], onProgress);
    } finally {
      _isScanning = false;
    }
  }

  void _resetCounters() {
    _totalFiles = 0;
    _scannedFiles = 0;
    _threatsFound = 0;
  }

  Future<List<String>> _getQuickScanDirectories() async {
    final List<String> directories = [];

    try {
      // External storage directories
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        directories.add('${externalDir.path}/Download');
        directories.add('${externalDir.path}/Documents');
      }

      // Download folder
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        directories.add(downloadDir.path);
      }

      // Documents folder
      final documentsDir = Directory('/storage/emulated/0/Documents');
      if (await documentsDir.exists()) {
        directories.add(documentsDir.path);
      }
    } catch (e) {
      // Fallback to temp directory if permissions denied
      final tempDir = await getTemporaryDirectory();
      directories.add(tempDir.path);
    }

    return directories;
  }

  Future<List<String>> _getFullScanDirectories() async {
    final List<String> directories = [];

    try {
      // Try to scan main storage
      final mainStorage = Directory('/storage/emulated/0');
      if (await mainStorage.exists()) {
        directories.add(mainStorage.path);
      }
    } catch (e) {
      // Fallback to accessible directories
      directories.addAll(await _getQuickScanDirectories());
    }

    return directories;
  }

  Future<ScanResult> _performScan(
    List<String> directories,
    Function(double) onProgress,
  ) async {
    final List<ThreatInfo> threats = [];
    final startTime = DateTime.now();

    // First pass: count total files
    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        _totalFiles += await _countFiles(dir);
      }
    }

    // Second pass: scan files
    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        final dirThreats = await _scanDirectory(dir, onProgress);
        threats.addAll(dirThreats);
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    // Save scan record
    await DatabaseService.instance.addScanRecord({
      'timestamp': endTime.millisecondsSinceEpoch,
      'type': 'full_scan',
      'filesScanned': _scannedFiles,
      'threatsFound': _threatsFound,
      'duration': duration.inSeconds,
    });

    // Show notification
    await NotificationService.instance.showScanCompleteNotification(
      filesScanned: _scannedFiles,
      threatsFound: _threatsFound,
    );

    return ScanResult(
      filesScanned: _scannedFiles,
      threatsFound: threats,
      duration: duration,
    );
  }

  Future<int> _countFiles(Directory dir) async {
    int count = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          count++;
        }
      }
    } catch (e) {
      // Permission denied or other errors
    }
    return count;
  }

  Future<List<ThreatInfo>> _scanDirectory(
    Directory dir,
    Function(double) onProgress,
  ) async {
    final List<ThreatInfo> threats = [];

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final threat = await _scanFile(entity);
          if (threat != null) {
            threats.add(threat);
            _threatsFound++;
            
            // Save threat to database
            await DatabaseService.instance.addThreat(
              entity.path,
              threat.toMap(),
            );

            // Show threat notification
            await NotificationService.instance.showThreatNotification(
              title: 'Threat Detected!',
              body: '${threat.name} found in ${entity.path.split('/').last}',
            );
          }

          _scannedFiles++;
          onProgress(progress);
        }
      }
    } catch (e) {
      // Permission denied or other errors - continue scanning
    }

    return threats;
  }

  Future<ThreatInfo?> _scanFile(File file) async {
    try {
      // Get file info
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      // Skip very large files (>100MB) for performance
      if (fileSize > 100 * 1024 * 1024) {
        return null;
      }

      // 1. Check file hash against malware signatures
      final hash = await _calculateFileHash(file);
      if (await _isKnownMalwareHash(hash)) {
        return ThreatInfo(
          name: fileName,
          type: 'Malware',
          severity: 'High',
          description: 'File matches known malware signature',
          hash: hash,
        );
      }

      // 2. Check APK files
      if (fileName.endsWith('.apk')) {
        final apkThreat = await _scanApk(file);
        if (apkThreat != null) return apkThreat;
      }

      // 3. Check suspicious file extensions
      if (_hasSuspiciousExtension(fileName)) {
        return ThreatInfo(
          name: fileName,
          type: 'Suspicious File',
          severity: 'Medium',
          description: 'Potentially dangerous file extension',
        );
      }

      // 4. Check file content for malicious patterns
      if (fileSize < 1024 * 1024) {
        // Only scan files < 1MB
        final contentThreat = await _scanFileContent(file, fileName);
        if (contentThreat != null) return contentThreat;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      return '';
    }
  }

  Future<bool> _isKnownMalwareHash(String hash) async {
    final malwareHashes = DatabaseService.instance.getMalwareHashes();
    return malwareHashes.contains(hash);
  }

  Future<ThreatInfo?> _scanApk(File file) async {
    final fileName = file.path.split('/').last;

    // Check if APK is from known fake apps
    // This is a simplified check - real implementation would parse APK manifest
    final suspiciousKeywords = [
      'fake',
      'hack',
      'crack',
      'mod',
      'cheat',
      'virus',
      'malware',
    ];

    final lowerName = fileName.toLowerCase();
    for (final keyword in suspiciousKeywords) {
      if (lowerName.contains(keyword)) {
        return ThreatInfo(
          name: fileName,
          type: 'Suspicious APK',
          severity: 'High',
          description: 'APK filename contains suspicious keywords',
        );
      }
    }

    return null;
  }

  bool _hasSuspiciousExtension(String fileName) {
    final suspiciousExtensions = [
      '.exe',
      '.bat',
      '.cmd',
      '.com',
      '.pif',
      '.scr',
      '.vbs',
      '.js',
    ];

    final lowerName = fileName.toLowerCase();
    return suspiciousExtensions.any((ext) => lowerName.endsWith(ext));
  }

  Future<ThreatInfo?> _scanFileContent(File file, String fileName) async {
    try {
      final content = await file.readAsString();
      final lowerContent = content.toLowerCase();

      // Check for phishing keywords
      final phishingKeywords = DatabaseService.instance.getPhishingKeywords();
      int suspiciousCount = 0;

      for (final keyword in phishingKeywords) {
        if (lowerContent.contains(keyword.toLowerCase())) {
          suspiciousCount++;
        }
      }

      // If multiple phishing keywords found, flag as suspicious
      if (suspiciousCount >= 3) {
        return ThreatInfo(
          name: fileName,
          type: 'Phishing Content',
          severity: 'Medium',
          description: 'File contains suspicious phishing-related text',
        );
      }

      return null;
    } catch (e) {
      // File is binary or unreadable
      return null;
    }
  }

  /// Scan installed apps (requires Android-specific implementation)
  Future<List<ThreatInfo>> scanInstalledApps() async {
    // This requires native Android code to get installed packages
    // Placeholder for now
    return [];
  }
}

class ScanResult {
  final int filesScanned;
  final List<ThreatInfo> threatsFound;
  final Duration duration;

  ScanResult({
    required this.filesScanned,
    required this.threatsFound,
    required this.duration,
  });
}

class ThreatInfo {
  final String name;
  final String type;
  final String severity;
  final String description;
  final String? hash;

  ThreatInfo({
    required this.name,
    required this.type,
    required this.severity,
    required this.description,
    this.hash,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'severity': severity,
      'description': description,
      if (hash != null) 'hash': hash,
    };
  }
}
