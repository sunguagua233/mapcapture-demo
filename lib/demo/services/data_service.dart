import 'package:mapcapture/demo/models/marker.dart';
import 'package:mapcapture/demo/models/trip.dart';

/// In-memory data service for demo
///
/// This service manages all data in memory.
/// Data will be lost when the app restarts.
class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Storage
  final List<Trip> _trips = [];
  final List<Marker> _markers = [];
  int _nextTripId = 1;
  int _nextMarkerId = 1;

  // ===== Trip Operations =====

  List<Trip> getAllTrips() {
    return List.unmodifiable(_trips);
  }

  Trip? getTripById(int id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  int getMarkerCountForTrip(int tripId) {
    return _markers.where((m) => m.tripId == tripId).length;
  }

  Trip createTrip({
    required String name,
    String? coverImagePath,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final trip = Trip(
      id: _nextTripId++,
      name: name,
      coverImagePath: coverImagePath,
      startDate: startDate,
      endDate: endDate,
      displayOrder: _trips.length,
    );
    _trips.add(trip);
    return trip;
  }

  Trip? updateTrip(int id, {String? name, String? coverImagePath}) {
    final trip = getTripById(id);
    if (trip == null) return null;

    final index = _trips.indexWhere((t) => t.id == id);
    _trips[index] = trip.copyWith(
      name: name ?? trip.name,
      coverImagePath: coverImagePath ?? trip.coverImagePath,
    );
    return _trips[index];
  }

  bool deleteTrip(int id) {
    return _trips.removeWhere((t) => t.id == id) > 0;
  }

  // ===== Marker Operations =====

  List<Marker> getMarkersByTripId(int tripId) {
    return _markers
        .where((m) => m.tripId == tripId)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Marker? getMarkerById(int id) {
    try {
      return _markers.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  Marker createMarker({
    required int tripId,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
    String? link,
  }) {
    final tripMarkers = getMarkersByTripId(tripId);
    final marker = Marker(
      id: _nextMarkerId++,
      tripId: tripId,
      title: title,
      address: address,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      link: link,
      displayOrder: tripMarkers.length,
    );
    _markers.add(marker);
    return marker;
  }

  Marker? updateMarker(
    int id, {
    String? title,
    String? address,
    String? notes,
    String? link,
  }) {
    final marker = getMarkerById(id);
    if (marker == null) return null;

    final index = _markers.indexWhere((m) => m.id == id);
    _markers[index] = marker.copyWith(
      title: title ?? marker.title,
      address: address ?? marker.address,
      notes: notes ?? marker.notes,
      link: link ?? marker.link,
    );
    return _markers[index];
  }

  bool deleteMarker(int id) {
    return _markers.removeWhere((m) => m.id == id) > 0;
  }

  // ===== Utility Methods =====

  void clearAll() {
    _trips.clear();
    _markers.clear();
    _nextTripId = 1;
    _nextMarkerId = 1;
  }

  // Add demo data
  void addDemoData() {
    final trip1 = createTrip(name: '云南之旅');
    createMarker(
      tripId: trip1.id,
      title: '大理古城',
      address: '云南省大理白族自治州大理市',
      latitude: 25.6065,
      longitude: 100.2678,
      notes: '古城漫步，品尝过桥米线',
    );
    createMarker(
      tripId: trip1.id,
      title: '丽江古城',
      address: '云南省丽江市古城区',
      latitude: 26.8722,
      longitude: 100.2297,
      notes: '世界文化遗产，纳西族聚居地',
      link: 'https://example.com/lijiang',
    );
    createMarker(
      tripId: trip1.id,
      title: '玉龙雪山',
      address: '云南省丽江市玉龙纳西族自治县',
      latitude: 27.1050,
      longitude: 100.2352,
      notes: '北半球最近赤道的雪山',
    );

    final trip2 = createTrip(
      name: '日本关西游',
      startDate: DateTime(2024, 4, 1),
      endDate: DateTime(2024, 4, 7),
    );
    createMarker(
      tripId: trip2.id,
      title: '清水寺',
      address: '日本京都府京都市东山区清水',
      latitude: 34.9949,
      longitude: 135.7850,
      notes: '京都最古老的寺院',
    );
    createMarker(
      tripId: trip2.id,
      title: '大阪城',
      address: '日本大阪府大阪市中央区大阪城',
      latitude: 34.6873,
      longitude: 135.5262,
      notes: '日本三大城堡之一',
    );
  }
}
