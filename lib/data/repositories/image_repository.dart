import 'package:mapcapture/data/database/database.dart';

/// ImageRepository interface
///
/// Defines all image-related database operations.
abstract class ImageRepository {
  /// Get all images for a marker
  Future<List<MarkerImage>> getImagesByMarkerId(int markerId);

  /// Add an image to a marker
  Future<int> addImage(ImagesCompanion image);

  /// Delete an image
  Future<bool> deleteImage(int id);

  /// Delete all images for a marker
  Future<int> deleteImagesByMarkerId(int markerId);

  /// Reorder images within a marker
  Future<void> reorderImages(int markerId, List<int> imageIds);

  /// Get first image for a marker (for cover)
  Future<MarkerImage?> getFirstImageByMarkerId(int markerId);

  /// Update image path
  Future<bool> updateImagePath(int id, String newPath);
}

/// ImageRepository implementation
class ImageRepositoryImpl implements ImageRepository {
  final AppDatabase _database;

  ImageRepositoryImpl(this._database);

  @override
  Future<List<MarkerImage>> getImagesByMarkerId(int markerId) {
    return (_database.select(_database.images)
          ..where((img) => img.markerId.equals(markerId))
          ..orderBy([(img) => OrderingTerm.asc(img.displayOrder)]))
        .get();
  }

  @override
  Future<int> addImage(ImagesCompanion image) {
    return _database.into(_database.images).insert(image);
  }

  @override
  Future<bool> deleteImage(int id) {
    return _database.delete(_database.images).where((img) => img.id.equals(id)) > 0;
  }

  @override
  Future<int> deleteImagesByMarkerId(int markerId) {
    return _database
        .delete(_database.images)
        .where((img) => img.markerId.equals(markerId));
  }

  @override
  Future<void> reorderImages(int markerId, List<int> imageIds) {
    return _database.transaction(() async {
      for (int i = 0; i < imageIds.length; i++) {
        await _database
            .update(_database.images)
            .where((img) => img.id.equals(imageIds[i]))
            .write(ImagesCompanion(displayOrder: Value(i)));
      }
    });
  }

  @override
  Future<MarkerImage?> getFirstImageByMarkerId(int markerId) {
    return (_database.select(_database.images)
          ..where((img) => img.markerId.equals(markerId))
          ..orderBy([(img) => OrderingTerm.asc(img.displayOrder)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<bool> updateImagePath(int id, String newPath) {
    return _database
        .update(_database.images)
        .where((img) => img.id.equals(id))
        .write(ImagesCompanion(filePath: Value(newPath))) > 0;
  }
}
