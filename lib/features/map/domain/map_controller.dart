import 'package:flutter/foundation.dart';
import 'package:mapcapture/core/constants/app_constants.dart';
import 'package:mapcapture/data/models/marker_model.dart';
import 'package:mapcapture/data/providers/database_providers.dart';
import 'package:mapcapture/features/map/data/location_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_controller.g.dart';

/// Map controller state
class MapControllerState {
  final List<MarkerEntity> markers;
  final MarkerEntity? selectedMarker;
  final bool isLoading;
  final String? error;
  final double latitude;
  final double longitude;
  final double zoom;

  const MapControllerState({
    this.markers = const [],
    this.selectedMarker,
    this.isLoading = false,
    this.error,
    this.latitude = 39.9042, // Default: Beijing
    this.longitude = 116.4074,
    this.zoom = AppConstants.defaultMapZoom,
  });

  MapControllerState copyWith({
    List<MarkerEntity>? markers,
    MarkerEntity? selectedMarker,
    bool? isLoading,
    String? error,
    double? latitude,
    double? longitude,
    double? zoom,
  }) {
    return MapControllerState(
      markers: markers ?? this.markers,
      selectedMarker: selectedMarker ?? this.selectedMarker,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zoom: zoom ?? this.zoom,
    );
  }
}

/// Map controller - manages map state and operations
@riverpod
class MapController extends _$MapController {
  LocationService? _locationService;

  @override
  MapControllerState build() {
    _locationService = LocationService();
    return const MapControllerState();
  }

  /// Load markers for a trip
  Future<void> loadMarkers(int tripId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final markerRepo = ref.read(markerRepositoryProvider);
      final dbMarkers = await markerRepo.getMarkersByTripId(tripId);
      final markers = dbMarkers.map((m) => MarkerEntity.fromMarker(m)).toList();

      state = state.copyWith(
        markers: markers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new marker at the given coordinates
  Future<MarkerEntity?> addMarker(
    int tripId,
    double latitude,
    double longitude,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get address via reverse geocoding
      final geocodingResult =
          await _locationService!.reverseGeocode(latitude, longitude);

      // Create marker entity
      final marker = MarkerEntity(
        tripId: tripId,
        title: geocodingResult.address,
        address: geocodingResult.address,
        latitude: latitude,
        longitude: longitude,
      );

      // Save to database
      final markerRepo = ref.read(markerRepositoryProvider);
      final id = await markerRepo.createMarker(marker.toCompanion());

      // Update marker with ID
      final savedMarker = marker.copyWith(id: id);

      // Update state
      final updatedMarkers = [...state.markers, savedMarker];
      state = state.copyWith(
        markers: updatedMarkers,
        isLoading: false,
      );

      return savedMarker;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update an existing marker
  Future<bool> updateMarker(MarkerEntity marker) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final markerRepo = ref.read(markerRepositoryProvider);
      final success = await markerRepo.updateMarker(marker.toCompanion().toMarker(marker.id));

      if (success) {
        final updatedMarkers = state.markers.map((m) {
          return m.id == marker.id ? marker : m;
        }).toList();

        state = state.copyWith(
          markers: updatedMarkers,
          isLoading: false,
        );
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete a marker
  Future<bool> deleteMarker(int markerId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final markerRepo = ref.read(markerRepositoryProvider);
      final success = await markerRepo.deleteMarker(markerId);

      if (success) {
        final updatedMarkers =
            state.markers.where((m) => m.id != markerId).toList();

        state = state.copyWith(
          markers: updatedMarkers,
          selectedMarker: state.selectedMarker?.id == markerId
              ? null
              : state.selectedMarker,
          isLoading: false,
        );
        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Select a marker
  void selectMarker(MarkerEntity? marker) {
    state = state.copyWith(selectedMarker: marker);

    // Update map center to marker location
    if (marker != null) {
      state = state.copyWith(
        latitude: marker.latitude,
        longitude: marker.longitude,
      );
    }
  }

  /// Update map camera position
  void updateCameraPosition(double latitude, double longitude, double zoom) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Extension to convert companion to marker (helper for update)
extension on MarkersCompanion {
  TripMarker toMarker(int id) {
    return TripMarker(
      id: id,
      tripId: tripId.value,
      title: title.value,
      address: address.value,
      latitude: latitude.value,
      longitude: longitude.value,
      notes: notes.value,
      link: link.value,
      displayOrder: displayOrder.value,
      createdAt: createdAt.value,
    );
  }
}
