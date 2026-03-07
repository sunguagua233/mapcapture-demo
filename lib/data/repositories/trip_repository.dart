import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/models.dart';

class TripRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  static const String tableName = 'trips';

  // Create a new trip
  Future<Trip> create(Trip trip) async {
    await _db.insert(tableName, trip.toDbMap());
    return trip;
  }

  // Get trip by ID
  Future<Trip?> getById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final trip = Trip.fromDbMap(results.first);
    return trip.copyWith(markerCount: await _getMarkerCount(id));
  }

  // Get all trips ordered by display_order
  Future<List<Trip>> getAll() async {
    final results = await _db.query(
      tableName,
      orderBy: 'display_order ASC, created_at DESC',
    );

    final trips = <Trip>[];
    for (final row in results) {
      final trip = Trip.fromDbMap(row);
      final markerCount = await _getMarkerCount(trip.id);
      trips.add(trip.copyWith(markerCount: markerCount));
    }

    return trips;
  }

  // Get trip count
  Future<int> count() async {
    final results = await _db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Update trip
  Future<int> update(Trip trip) async {
    return await _db.update(
      tableName,
      trip.toDbMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  // Delete trip
  Future<int> delete(String id) async {
    return await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get max display order
  Future<int> getMaxDisplayOrder() async {
    final results = await _db.rawQuery(
      'SELECT MAX(display_order) as max_order FROM $tableName',
    );
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Reorder trips
  Future<void> reorder(List<String> tripIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (int i = 0; i < tripIds.length; i++) {
        await txn.update(
          tableName,
          {'display_order': i},
          where: 'id = ?',
          whereArgs: [tripIds[i]],
        );
      }
    });
  }

  // Get trips with date range
  Future<List<Trip>> getByDateRange(DateTime start, DateTime end) async {
    final startTimestamp = start.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = end.millisecondsSinceEpoch ~/ 1000;

    final results = await _db.query(
      tableName,
      where: '''
        (start_date IS NOT NULL AND start_date <= ?) OR
        (end_date IS NOT NULL AND end_date >= ?) OR
        (start_date IS NULL AND end_date IS NULL)
      ''',
      whereArgs: [endTimestamp, startTimestamp],
      orderBy: 'display_order ASC',
    );

    final trips = <Trip>[];
    for (final row in results) {
      final trip = Trip.fromDbMap(row);
      final markerCount = await _getMarkerCount(trip.id);
      trips.add(trip.copyWith(markerCount: markerCount));
    }

    return trips;
  }

  // Update trip cover image
  Future<int> updateCoverImage(String tripId, String? imagePath) async {
    return await _db.update(
      tableName,
      {'cover_image_path': imagePath},
      where: 'id = ?',
      whereArgs: [tripId],
    );
  }

  // Search trips by name
  Future<List<Trip>> search(String query) async {
    final results = await _db.query(
      tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'display_order ASC, created_at DESC',
    );

    final trips = <Trip>[];
    for (final row in results) {
      final trip = Trip.fromDbMap(row);
      final markerCount = await _getMarkerCount(trip.id);
      trips.add(trip.copyWith(markerCount: markerCount));
    }

    return trips;
  }

  // Helper: Get marker count for a trip
  Future<int> _getMarkerCount(String tripId) async {
    final results = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM markers WHERE trip_id = ?',
      [tripId],
    );
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Batch insert trips
  Future<void> insertBatch(List<Trip> trips) async {
    final db = await _db.database;
    final batch = db.batch();

    for (final trip in trips) {
      batch.insert(tableName, trip.toDbMap());
    }

    await batch.commit(noResult: true);
  }
}
