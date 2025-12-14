import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageCleanerService {
  static final StorageCleanerService instance = StorageCleanerService._internal();
  factory StorageCleanerService() => instance;
  StorageCleanerService._internal();

  /// Analyze storage usage
  Future<StorageAnalysis> analyzeStorage() async {
    int cacheSize = 0;
    int tempSize = 0;
    int duplicateSize = 0;
    int largeFilesSize = 0;

    try {
      // Analyze cache
      final cacheDir = await getTemporaryDirectory();
      cacheSize = await _calculateDirectorySize(cacheDir);

      // Analyze downloads (look for duplicates)
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final duplicateAnalysis = await _findDuplicates(downloadDir);
        duplicateSize = duplicateAnalysis.totalSize;
      }

      // Find large files (>50MB)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        largeFilesSize = await _findLargeFiles(
          Directory('/storage/emulated/0'),
          minSize: 50 * 1024 * 1024, // 50MB
        );
      }

    } catch (e) {
      // Permission error - return partial data
    }

    final totalCleanable = cacheSize + tempSize + duplicateSize;

    return StorageAnalysis(
      cacheSize: cacheSize,
      tempFilesSize: tempSize,
      duplicateFilesSize: duplicateSize,
      largeFilesSize: largeFilesSize,
      totalCleanableSize: totalCleanable,
      spaceSaved: 0,
    );
  }

  /// Clean cache files
  Future<int> cleanCache() async {
    int cleaned = 0;

    try {
      final cacheDir = await getTemporaryDirectory();
      cleaned = await _deleteDirectoryContents(cacheDir);
    } catch (e) {
      // Permission error
    }

    return cleaned;
  }

  /// Clean temporary files
  Future<int> cleanTempFiles() async {
    int cleaned = 0;

    try {
      // Clean app temp directory
      final tempDir = await getTemporaryDirectory();
      cleaned += await _deleteDirectoryContents(tempDir);

      // Clean system temp if accessible
      final systemTemp = Directory('/sdcard/.tmp');
      if (await systemTemp.exists()) {
        cleaned += await _deleteDirectoryContents(systemTemp);
      }

    } catch (e) {
      // Permission error
    }

    return cleaned;
  }

  /// Find and report duplicate files
  Future<List<DuplicateFile>> findDuplicates() async {
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final result = await _findDuplicates(downloadDir);
        return result.duplicates;
      }
    } catch (e) {
      // Permission error
    }

    return [];
  }

  /// Get storage recommendations
  List<StorageRecommendation> getRecommendations(StorageAnalysis analysis) {
    final recommendations = <StorageRecommendation>[];

    if (analysis.cacheSize > 100 * 1024 * 1024) {
      // >100MB cache
      recommendations.add(StorageRecommendation(
        type: 'Cache',
        description: 'Clear app cache to free ${_formatSize(analysis.cacheSize)}',
        potentialSavings: analysis.cacheSize,
        priority: 'High',
      ));
    }

    if (analysis.duplicateFilesSize > 50 * 1024 * 1024) {
      // >50MB duplicates
      recommendations.add(StorageRecommendation(
        type: 'Duplicates',
        description: 'Remove duplicate files to save ${_formatSize(analysis.duplicateFilesSize)}',
        potentialSavings: analysis.duplicateFilesSize,
        priority: 'Medium',
      ));
    }

    if (analysis.largeFilesSize > 500 * 1024 * 1024) {
      // >500MB large files
      recommendations.add(StorageRecommendation(
        type: 'Large Files',
        description: 'Review large files (${_formatSize(analysis.largeFilesSize)} total)',
        potentialSavings: 0,
        priority: 'Low',
      ));
    }

    return recommendations;
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (e) {
            // File access error
          }
        }
      }
    } catch (e) {
      // Permission error
    }

    return size;
  }

  Future<int> _deleteDirectoryContents(Directory dir) async {
    int deleted = 0;

    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        try {
          if (entity is File) {
            deleted += await entity.length();
            await entity.delete();
          } else if (entity is Directory) {
            deleted += await _calculateDirectorySize(entity);
            await entity.delete(recursive: true);
          }
        } catch (e) {
          // Can't delete this file
        }
      }
    } catch (e) {
      // Permission error
    }

    return deleted;
  }

  Future<_DuplicateAnalysis> _findDuplicates(Directory dir) async {
    final Map<String, List<File>> filesByName = {};
    int totalSize = 0;
    final List<DuplicateFile> duplicates = [];

    try {
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final name = entity.path.split('/').last;
          filesByName.putIfAbsent(name, () => []);
          filesByName[name]!.add(entity);
        }
      }

      // Find duplicates
      for (final entry in filesByName.entries) {
        if (entry.value.length > 1) {
          final files = entry.value;
          final firstFile = files.first;
          final size = await firstFile.length();
          
          duplicates.add(DuplicateFile(
            name: entry.key,
            count: files.length,
            size: size,
            paths: files.map((f) => f.path).toList(),
          ));
          
          totalSize += size * (files.length - 1); // Exclude original
        }
      }

    } catch (e) {
      // Permission error
    }

    return _DuplicateAnalysis(
      duplicates: duplicates,
      totalSize: totalSize,
    );
  }

  Future<int> _findLargeFiles(Directory dir, {required int minSize}) async {
    int totalSize = 0;

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            if (size >= minSize) {
              totalSize += size;
            }
          } catch (e) {
            // File access error
          }
        }
      }
    } catch (e) {
      // Permission error
    }

    return totalSize;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class StorageAnalysis {
  final int cacheSize;
  final int tempFilesSize;
  final int duplicateFilesSize;
  final int largeFilesSize;
  final int totalCleanableSize;
  final int spaceSaved;

  StorageAnalysis({
    required this.cacheSize,
    required this.tempFilesSize,
    required this.duplicateFilesSize,
    required this.largeFilesSize,
    required this.totalCleanableSize,
    required this.spaceSaved,
  });

  String get totalCleanableFormatted => _formatSize(totalCleanableSize);
  String get cacheFormatted => _formatSize(cacheSize);
  String get tempFormatted => _formatSize(tempFilesSize);
  String get duplicatesFormatted => _formatSize(duplicateFilesSize);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _DuplicateAnalysis {
  final List<DuplicateFile> duplicates;
  final int totalSize;

  _DuplicateAnalysis({
    required this.duplicates,
    required this.totalSize,
  });
}

class DuplicateFile {
  final String name;
  final int count;
  final int size;
  final List<String> paths;

  DuplicateFile({
    required this.name,
    required this.count,
    required this.size,
    required this.paths,
  });
}

class StorageRecommendation {
  final String type;
  final String description;
  final int potentialSavings;
  final String priority;

  StorageRecommendation({
    required this.type,
    required this.description,
    required this.potentialSavings,
    required this.priority,
  });
}
