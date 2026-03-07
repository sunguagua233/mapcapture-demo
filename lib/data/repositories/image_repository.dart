import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import 'marker_repository.dart';

class ImageRepository {
  final MarkerRepository _markerRepository = MarkerRepository();

  // Get images directory
  Future<Directory> getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, AppConstants.imagesDir));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  // Get temp directory
  Future<Directory> getTempDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory(p.join(appDir.path, AppConstants.tempDir));

    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    return tempDir;
  }

  // Save image to persistent storage
  Future<String> saveImage(File sourceFile, {String? markerId}) async {
    final imagesDir = await getImagesDirectory();

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(sourceFile.path);
    final filename = '${markerId ?? 'img'}_$timestamp$extension';
    final targetPath = p.join(imagesDir.path, filename);

    // Copy file
    final targetFile = await sourceFile.copy(targetPath);
    return targetFile.path;
  }

  // Save temp image
  Future<String> saveTempImage(File sourceFile) async {
    final tempDir = await getTempDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(sourceFile.path);
    final filename = 'temp_$timestamp$extension';
    final targetPath = p.join(tempDir.path, filename);

    final targetFile = await sourceFile.copy(targetPath);
    return targetFile.path;
  }

  // Delete image file
  Future<void> deleteImageFile(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Delete all images for a marker
  Future<void> deleteMarkerImages(String markerId) async {
    final images = await _markerRepository.getImagesByMarkerId(markerId);

    for (final image in images) {
      await deleteImageFile(image.filePath);
    }

    // Database records will be deleted by CASCADE
  }

  // Clean up temp directory
  Future<void> cleanupTempFiles() async {
    final tempDir = await getTempDirectory();

    if (await tempDir.exists()) {
      final files = tempDir.listSync();

      // Delete files older than 1 hour
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoff)) {
            await file.delete();
          }
        }
      }
    }
  }

  // Clean up orphaned image files
  Future<int> cleanupOrphanedImages(List<String> validPaths) async {
    final imagesDir = await getImagesDirectory();
    final validSet = validPaths.toSet();

    if (!await imagesDir.exists()) return 0;

    final files = imagesDir.listSync();
    int deletedCount = 0;

    for (final file in files) {
      if (file is File) {
        if (!validSet.contains(file.path)) {
          await file.delete();
          deletedCount++;
        }
      }
    }

    return deletedCount;
  }

  // Get file size
  Future<int> getFileSize(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  // Check if file exists
  Future<bool> fileExists(String imagePath) async {
    final file = File(imagePath);
    return await file.exists();
  }

  // Get all image paths for a marker (including DB records)
  Future<List<String>> getMarkerImagePaths(String markerId) async {
    final images = await _markerRepository.getImagesByMarkerId(markerId);
    return images.map((e) => e.filePath).toList();
  }

  // Duplicate image (for creating copies)
  Future<String?> duplicateImage(String imagePath, {String? newMarkerId}) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    return await saveImage(file, markerId: newMarkerId);
  }

  // Get total storage size used by images
  Future<int> getTotalImageStorageSize() async {
    final imagesDir = await getImagesDirectory();

    if (!await imagesDir.exists()) return 0;

    final files = imagesDir.listSync();
    int totalSize = 0;

    for (final file in files) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    return totalSize;
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
}
