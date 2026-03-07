import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/models.dart';

class MarkerRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  static const String tableName = 'markers';
  static const String imagesTableName = 'marker_images';

  // Create a new marker
  Future<Marker> create(Marker marker) async {
    await _db.insert(tableName, marker.toDbMap());

    // Insert associated images
    if (marker.images.isNotEmpty) {
      await _insertImages(marker.images);
    }

    return marker;
  }

  // Get marker by ID with images
  Future<Marker?> getById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final marker = Marker.fromDbMap(results.first);
    final images = await getImagesByMarkerId(id);
    return marker.copyWith(images: images);
  }

  // Get all markers for a trip
  Future<List<Marker>> getByTripId(String tripId) async {
    final results = await _db.query(
      tableName,
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'display_order ASC, created_at ASC',
    );

    final markers = <Marker>[];
    for (final row in results) {
      final marker = Marker.fromDbMap(row);
      final images = await getImagesByMarkerId(marker.id);
      markers.add(marker.copyWith(images: images));
    }

    return markers;
  }

  // Get markers within bounds
  Future<List<Marker>> getWithinBounds(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng, {
    String? tripId,
  }) async {
    final where = tripId != null
        ? 'trip_id = ? AND latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?'
        : 'latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?';

    final whereArgs = tripId != null
        ? [tripId, minLat, maxLat, minLng, maxLng]
        : [minLat, maxLat, minLng, maxLng];

    final results = await _db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'display_order ASC',
    );

    return results.map((row) => Marker.fromDbMap(row)).toList();
  }

  // Get marker count for a trip
  Future<int> countByTripId(String tripId) async {
    final results = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE trip_id = ?',
      [tripId],
    );
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Update marker
  Future<int> update(Marker marker) async {
    return await _db.update(
      tableName,
      marker.toDbMap(),
      where: 'id = ?',
      whereArgs: [marker.id],
    );
  }

  // Delete marker
  Future<int> delete(String id) async {
    // Images will be deleted automatically due to CASCADE
    return await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all markers for a trip
  Future<int> deleteByTripId(String tripId) async {
    return await _db.delete(
      tableName,
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  // Get max display order for a trip
  Future<int> getMaxDisplayOrder(String tripId) async {
    final results = await _db.rawQuery(
      'SELECT MAX(display_order) as max_order FROM $tableName WHERE trip_id = ?',
      [tripId],
    );
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Reorder markers
  Future<void> reorder(String tripId, List<String> markerIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < markerIds.length; i++) {
        await txn.update(
          tableName,
          {'display_order': i},
          where: 'id = ?',
          whereArgs: [markerIds[i]],
        );
      }
    });
  }

  // Search markers by title or address
  Future<List<Marker>> search(String tripId, String query) async {
    final results = await _db.query(
      tableName,
      where: 'trip_id = ? AND (title LIKE ? OR address LIKE ?)',
      whereArgs: [tripId, '%$query%', '%$query%'],
      orderBy: 'display_order ASC',
    );

    final markers = <Marker>[];
    for (final row in results) {
      final marker = Marker.fromDbMap(row);
      final images = await getImagesByMarkerId(marker.id);
      markers.add(marker.copyWith(images: images));
    }

    return markers;
  }

  // Get markers by category
  Future<List<Marker>> getByCategory(String tripId, String category) async {
    final results = await _db.query(
      tableName,
      where: 'trip_id = ? AND category = ?',
      whereArgs: [tripId, category],
      orderBy: 'display_order ASC',
    );

    final markers = <Marker>[];
    for (final row in results) {
      final marker = Marker.fromDbMap(row);
      final images = await getImagesByMarkerId(marker.id);
      markers.add(marker.copyWith(images: images));
    }

    return markers;
  }

  // Get distinct categories for a trip
  Future<List<String>> getCategories(String tripId) async {
    final results = await _db.rawQuery(
      'SELECT DISTINCT category FROM $tableName WHERE trip_id = ? AND category IS NOT NULL ORDER BY category',
      [tripId],
    );
    return results.map((row) => row['category'] as String).toList();
  }

  // Batch insert markers
  Future<void> insertBatch(List<Marker> markers) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final marker in markers) {
        await txn.insert(tableName, marker.toDbMap());
        if (marker.images.isNotEmpty) {
          for (final image in marker.images) {
            await txn.insert(imagesTableName, image.toDbMap());
          }
        }
      }
    });
  }

  // ========== Image operations ==========

  // Get images for a marker
  Future<List<MarkerImage>> getImagesByMarkerId(String markerId) async {
    final results = await _db.query(
      imagesTableName,
      where: 'marker_id = ?',
      whereArgs: [markerId],
      orderBy: 'display_order ASC',
    );

    return results.map((row) => MarkerImage.fromDbMap(row)).toList();
  }

  // Add image to marker
  Future<MarkerImage> addImage(MarkerImage image) async {
    await _db.insert(imagesTableName, image.toDbMap());
    return image;
  }

  // Delete image
  Future<int> deleteImage(String imageId) async {
    return await _db.delete(
      imagesTableName,
      where: 'id = ?',
      whereArgs: [imageId],
    );
  }

  // Delete all images for a marker
  Future<int> deleteImagesByMarkerId(String markerId) async {
    return await _db.delete(
      imagesTableName,
      where: 'marker_id = ?',
      whereArgs: [markerId],
    );
  }

  // Reorder images
  Future<void> reorderImages(String markerId, List<String> imageIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < imageIds.length; i++) {
        await txn.update(
          imagesTableName,
          {'display_order': i},
          where: 'id = ?',
          whereArgs: [imageIds[i]],
        );
      }
    });
  }

  // Get max display order for images
  Future<int> getMaxImageDisplayOrder(String markerId) async {
    final results = await _db.rawQuery(
      'SELECT MAX(display_order) as max_order FROM $imagesTableName WHERE marker_id = ?',
      [markerId],
    );
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Helper: Insert images
  Future<void> _insertImages(List<MarkerImage> images) async {
    for (final image in images) {
      await _db.insert(imagesTableName, image.toDbMap());
    }
  }
}
