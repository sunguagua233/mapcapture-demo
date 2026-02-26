import 'package:mapcapture/data/database/database.dart';

/// MarkerRepository interface
///
/// Defines all marker-related database operations.
abstract class MarkerRepository {
  /// Get all markers for a trip
  Future<List<TripMarker>> getMarkersByTripId(int tripId);

  /// Get marker by id
  Future<TripMarker?> getMarkerById(int id);

  /// Create a new marker
  Future<int> createMarker(MarkersCompanion marker);

  /// Update an existing marker
  Future<bool> updateMarker(TripMarker marker);

  /// Delete a marker
  Future<bool> deleteMarker(int id);

  /// Reorder markers within a trip
  Future<void> reorderMarkers(int tripId, List<int> markerIds);

  /// Get marker with images
  Future<MarkerWithImages?> getMarkerWithImages(int markerId);

  /// Get all markers with images for a trip
  Future<List<MarkerWithImages>> getMarkersWithImagesByTripId(int tripId);
}

/// Data class for marker with its images
class MarkerWithImages {
  final TripMarker marker;
  final List<MarkerImage> images;

  MarkerWithImages({
    required this.marker,
    required this.images,
  });
}

/// MarkerRepository implementation
class MarkerRepositoryImpl implements MarkerRepository {
  final AppDatabase _database;

  MarkerRepositoryImpl(this._database);

  @override
  Future<List<TripMarker>> getMarkersByTripId(int tripId) {
    return (_database.select(_database.markers)
          ..where((m) => m.tripId.equals(tripId))
          ..orderBy([(m) => OrderingTerm.asc(m.displayOrder)])
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
        .get();
  }

  @override
  Future<TripMarker?> getMarkerById(int id) {
    return (_database.select(_database.markers)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> createMarker(MarkersCompanion marker) {
    return _database.into(_database.markers).insert(marker);
  }

  @override
  Future<bool> updateMarker(TripMarker marker) {
    return _database.update(_database.markers).replace(marker);
  }

  @override
  Future<bool> deleteMarker(int id) {
    return _database.delete(_database.markers).where((m) => m.id.equals(id)) > 0;
  }

  @override
  Future<void> reorderMarkers(int tripId, List<int> markerIds) {
    return _database.transaction(() async {
      for (int i = 0; i < markerIds.length; i++) {
        await _database
            .update(_database.markers)
            .where((m) => m.id.equals(markerIds[i]))
            .write(MarkersCompanion(displayOrder: Value(i)));
      }
    });
  }

  @override
  Future<MarkerWithImages?> getMarkerWithImages(int markerId) async {
    final marker = await getMarkerById(markerId);
    if (marker == null) return null;

    final images = await _database
        .select(_database.images)
        .where((img) => img.markerId.equals(markerId))
        .orderBy([(img) => OrderingTerm.asc(img.displayOrder)])
        .get();

    return MarkerWithImages(marker: marker, images: images);
  }

  @override
  Future<List<MarkerWithImages>> getMarkersWithImagesByTripId(
      int tripId) async {
    final markers = await getMarkersByTripId(tripId);
    final result = <MarkerWithImages>[];

    for (final marker in markers) {
      final images = await _database
          .select(_database.images)
          .where((img) => img.markerId.equals(marker.id))
          .orderBy([(img) => OrderingTerm.asc(img.displayOrder)])
          .get();

      result.add(MarkerWithImages(marker: marker, images: images));
    }

    return result;
  }
}
