import 'package:mapcapture/data/database/database.dart';

/// TripRepository interface
///
/// Defines all trip-related database operations.
abstract class TripRepository {
  /// Get all trips ordered by display order
  Future<List<Trip>> getAllTrips();

  /// Get trip by id
  Future<Trip?> getTripById(int id);

  /// Create a new trip
  Future<int> createTrip(TripsCompanion trip);

  /// Update an existing trip
  Future<bool> updateTrip(Trip trip);

  /// Delete a trip
  Future<bool> deleteTrip(int id);

  /// Update trip cover image
  Future<bool> updateCoverImage(int tripId, String imagePath);

  /// Reorder trips
  Future<void> reorderTrips(List<int> tripIds);

  /// Get trips with marker count
  Future<List<TripWithMarkerCount>> getTripsWithMarkerCount();
}

/// Data class for trip with marker count
class TripWithMarkerCount {
  final Trip trip;
  final int markerCount;

  TripWithMarkerCount({
    required this.trip,
    required this.markerCount,
  });
}

/// TripRepository implementation
class TripRepositoryImpl implements TripRepository {
  final AppDatabase _database;

  TripRepositoryImpl(this._database);

  @override
  Future<List<Trip>> getAllTrips() {
    return (_database.select(_database.trips)
          ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)])
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  @override
  Future<Trip?> getTripById(int id) {
    return (_database.select(_database.trips)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<int> createTrip(TripsCompanion trip) {
    return _database.into(_database.trips).insert(trip);
  }

  @override
  Future<bool> updateTrip(Trip trip) {
    return _database.update(_database.trips).replace(trip);
  }

  @override
  Future<bool> deleteTrip(int id) {
    return _database.delete(_database.trips).where((t) => t.id.equals(id)) > 0;
  }

  @override
  Future<bool> updateCoverImage(int tripId, String imagePath) {
    return _database.update(_database.trips)
        .where((t) => t.id.equals(tripId))
        .write(TripsCompanion(coverImagePath: Value(imagePath))) > 0;
  }

  @override
  Future<void> reorderTrips(List<int> tripIds) {
    return _database.transaction(() async {
      for (int i = 0; i < tripIds.length; i++) {
        await _database
            .update(_database.trips)
            .where((t) => t.id.equals(tripIds[i]))
            .write(TripsCompanion(displayOrder: Value(i)));
      }
    });
  }

  @override
  Future<List<TripWithMarkerCount>> getTripsWithMarkerCount() async {
    final trips = await getAllTrips();
    final result = <TripWithMarkerCount>[];

    for (final trip in trips) {
      final count = await _database
          .select(_database.markers)
          .where((m) => m.tripId.equals(trip.id))
          .get()
          .then((markers) => markers.length);

      result.add(TripWithMarkerCount(trip: trip, markerCount: count));
    }

    return result;
  }
}
