import 'package:flutter/foundation.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class TripProvider extends ChangeNotifier {
  final TripRepository _tripRepository = TripRepository();

  // State
  List<Trip> _trips = [];
  Trip? _currentTrip;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Trip> get trips => List.unmodifiable(_trips);
  Trip? get currentTrip => _currentTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTrips => _trips.isNotEmpty;

  // Initialize - load all trips
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _trips = await _tripRepository.getAll();
      _clearError();
    } catch (e) {
      _setError('Failed to load trips: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new trip
  Future<Trip?> createTrip({
    required String name,
    String? coverImagePath,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    try {
      final displayOrder = await _tripRepository.getMaxDisplayOrder() + 1;
      final trip = Trip.create(
        name: name,
        coverImagePath: coverImagePath,
        startDate: startDate,
        endDate: endDate,
        displayOrder: displayOrder,
      );

      await _tripRepository.create(trip);
      _trips = await _tripRepository.getAll();
      _clearError();

      return trip;
    } catch (e) {
      _setError('Failed to create trip: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update a trip
  Future<bool> updateTrip(Trip trip) async {
    _setLoading(true);
    try {
      await _tripRepository.update(trip);

      // Update local list
      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip.copyWith(markerCount: _trips[index].markerCount);
      }

      // Update current trip if needed
      if (_currentTrip?.id == trip.id) {
        _currentTrip = trip.copyWith(markerCount: _currentTrip?.markerCount ?? 0);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update trip: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a trip
  Future<bool> deleteTrip(String tripId) async {
    _setLoading(true);
    try {
      await _tripRepository.delete(tripId);

      _trips.removeWhere((t) => t.id == tripId);

      if (_currentTrip?.id == tripId) {
        _currentTrip = null;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete trip: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set current trip
  void setCurrentTrip(Trip? trip) {
    _currentTrip = trip;
    notifyListeners();
  }

  // Get trip by ID
  Future<Trip?> getTripById(String id) async {
    try {
      return await _tripRepository.getById(id);
    } catch (e) {
      _setError('Failed to get trip: $e');
      return null;
    }
  }

  // Reorder trips
  Future<bool> reorderTrips(List<String> tripIds) async {
    try {
      await _tripRepository.reorder(tripIds);
      _trips = await _tripRepository.getAll();
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to reorder trips: $e');
      return false;
    }
  }

  // Update trip cover image
  Future<bool> updateCoverImage(String tripId, String? imagePath) async {
    try {
      await _tripRepository.updateCoverImage(tripId, imagePath);

      final index = _trips.indexWhere((t) => t.id == tripId);
      if (index != -1) {
        _trips[index] = _trips[index].copyWith(coverImagePath: imagePath);
      }

      if (_currentTrip?.id == tripId) {
        _currentTrip = _currentTrip?.copyWith(coverImagePath: imagePath);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to update cover image: $e');
      return false;
    }
  }

  // Search trips
  Future<List<Trip>> searchTrips(String query) async {
    if (query.isEmpty) {
      return trips;
    }

    try {
      return await _tripRepository.search(query);
    } catch (e) {
      _setError('Failed to search trips: $e');
      return [];
    }
  }

  // Refresh trips list
  Future<void> refresh() async {
    await initialize();
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
