import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/app_constants.dart';
import '../data/models/models.dart';

/// Storage service for managing files and app storage
class StorageService {
  // Get application documents directory
  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Get temporary directory
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  // Ensure directory exists
  Future<Directory> ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Check and request storage permissions
  Future<bool> requestStoragePermissions() async {
    // For Android 13+ (API 33+), we need specific permissions
    if (await _isAndroid13OrHigher()) {
      final photosPermission = await Permission.photos.request();
      final videosPermission = await Permission.videos.request();

      return photosPermission.isGranted || videosPermission.isGranted;
    }

    // For older Android versions
    final storagePermission = await Permission.storage.request();
    return storagePermission.isGranted;
  }

  // Check if device is Android 13+
  Future<bool> _isAndroid13OrHigher() async {
    // This is a simplified check
    // In production, use device_info_plus package
    return false;
  }

  // Save image to app storage
  Future<String?> saveImage(File sourceFile, {String? subDir}) async {
    try {
      final appDir = await getAppDirectory();

      String targetPath;
      if (subDir != null) {
        final dir = await ensureDirectory(p.join(appDir.path, subDir));
        targetPath = p.join(dir.path, p.basename(sourceFile.path));
      } else {
        targetPath = p.join(appDir.path, p.basename(sourceFile.path));
      }

      // Copy file to target location
      final targetFile = await sourceFile.copy(targetPath);
      return targetFile.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  // Delete file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Delete directory
  Future<bool> deleteDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting directory: $e');
      return false;
    }
  }

  // Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  // Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Get directory size
  Future<int> getDirectorySize(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // List files in directory
  Future<List<File>> listFiles(String dirPath, {String extension = ''}) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return [];
      }

      final files = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File) {
          if (extension.isEmpty || p.extension(entity.path) == extension) {
            files.add(entity);
          }
        }
      }
      return files;
    } catch (e) {
      return [];
    }
  }

  // Clean temporary files
  Future<int> cleanTempFiles({Duration? olderThan}) async {
    try {
      final tempDir = await getTempDirectory();
      if (!await tempDir.exists()) {
        return 0;
      }

      final cutoff = DateTime.now().subtract(olderThan ?? const Duration(hours: 1));
      int deletedCount = 0;

      await for (final entity in tempDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Clear all app data (useful for logout/reset)
  Future<bool> clearAllData() async {
    try {
      final appDir = await getAppDirectory();
      await deleteDirectory(appDir.path);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Export data (for backup)
  Future<String?> exportData(List<Trip> trips, List<Marker> markers) async {
    try {
      // Create export directory
      final appDir = await getAppDirectory();
      final exportDir = await ensureDirectory(p.join(appDir.path, 'exports'));

      // Create export file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportFile = File(p.join(exportDir.path, 'export_$timestamp.json'));

      final exportData = {
        'version': AppConstants.appVersion,
        'exported_at': timestamp,
        'trips': trips.map((t) => t.toJson()).toList(),
        'markers': markers.map((m) => m.toJson()).toList(),
      };

      await exportFile.writeAsString(exportData.toString());
      return exportFile.path;
    } catch (e) {
      print('Error exporting data: $e');
      return null;
    }
  }

  // Import data (from backup)
  Future<Map<String, dynamic>?> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      // Parse JSON and return
      // This would be implemented based on your import needs
      return {'success': true};
    } catch (e) {
      print('Error importing data: $e');
      return null;
    }
  }
}
