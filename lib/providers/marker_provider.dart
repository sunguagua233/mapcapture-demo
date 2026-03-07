import 'package:flutter/foundation.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class MarkerProvider extends ChangeNotifier {
  final MarkerRepository _markerRepository = MarkerRepository();

  // State
  List<Marker> _markers = [];
  Marker? _selectedMarker;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Marker> get markers => List.unmodifiable(_markers);
  Marker? get selectedMarker => _selectedMarker;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMarkers => _markers.isNotEmpty;

  // Load markers for a trip
  Future<void> loadMarkers(String tripId) async {
    _setLoading(true);
    try {
      _markers = await _markerRepository.getByTripId(tripId);
      _clearError();
    } catch (e) {
      _setError('Failed to load markers: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a new marker
  Future<Marker?> addMarker(Marker marker) async {
    _setLoading(true);
    try {
      // Get display order
      final displayOrder = await _markerRepository.getMaxDisplayOrder(marker.tripId) + 1;
      final newMarker = marker.copyWith(displayOrder: displayOrder);

      await _markerRepository.create(newMarker);
      _markers = await _markerRepository.getByTripId(marker.tripId);
      _clearError();

      return newMarker;
    } catch (e) {
      _setError('Failed to add marker: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update a marker
  Future<bool> updateMarker(Marker marker) async {
    _setLoading(true);
    try {
      await _markerRepository.update(marker);

      final index = _markers.indexWhere((m) => m.id == marker.id);
      if (index != -1) {
        _markers[index] = marker;
      }

      if (_selectedMarker?.id == marker.id) {
        _selectedMarker = marker;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update marker: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a marker
  Future<bool> deleteMarker(String markerId) async {
    _setLoading(true);
    try {
      await _markerRepository.delete(markerId);

      _markers.removeWhere((m) => m.id == markerId);

      if (_selectedMarker?.id == markerId) {
        _selectedMarker = null;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete marker: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Select a marker
  void selectMarker(Marker? marker) {
    _selectedMarker = marker;
    notifyListeners();
  }

  // Get marker by ID
  Future<Marker?> getMarkerById(String id) async {
    try {
      return await _markerRepository.getById(id);
    } catch (e) {
      _setError('Failed to get marker: $e');
      return null;
    }
  }

  // Reorder markers
  Future<bool> reorderMarkers(String tripId, List<String> markerIds) async {
    try {
      await _markerRepository.reorder(tripId, markerIds);
      _markers = await _markerRepository.getByTripId(tripId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to reorder markers: $e');
      return false;
    }
  }

  // Search markers
  Future<List<Marker>> searchMarkers(String tripId, String query) async {
    if (query.isEmpty) {
      return markers;
    }

    try {
      return await _markerRepository.search(tripId, query);
    } catch (e) {
      _setError('Failed to search markers: $e');
      return [];
    }
  }

  // Get markers by category
  Future<List<Marker>> getMarkersByCategory(String tripId, String category) async {
    try {
      return await _markerRepository.getByCategory(tripId, category);
    } catch (e) {
      _setError('Failed to get markers by category: $e');
      return [];
    }
  }

  // Get categories for a trip
  Future<List<String>> getCategories(String tripId) async {
    try {
      return await _markerRepository.getCategories(tripId);
    } catch (e) {
      _setError('Failed to get categories: $e');
      return [];
    }
  }

  // Get markers within bounds
  Future<List<Marker>> getMarkersWithinBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    String? tripId,
  }) async {
    try {
      return await _markerRepository.getWithinBounds(
        minLat,
        maxLat,
        minLng,
        maxLng,
        tripId: tripId,
      );
    } catch (e) {
      _setError('Failed to get markers in bounds: $e');
      return [];
    }
  }

  // Clear all markers
  void clearMarkers() {
    _markers = [];
    _selectedMarker = null;
    notifyListeners();
  }

  // Batch insert markers
  Future<bool> insertMarkersBatch(List<Marker> markers) async {
    _setLoading(true);
    try {
      await _markerRepository.insertBatch(markers);
      if (markers.isNotEmpty) {
        _markers = await _markerRepository.getByTripId(markers.first.tripId);
      }
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to insert markers: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
