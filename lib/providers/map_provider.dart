import 'package:flutter/foundation.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';

import '../core/constants/app_constants.dart';
import '../data/models/models.dart';

class MapProvider extends ChangeNotifier {
  // Map controller
  AMapController? _mapController;

  // Map state
  LatLng? _cameraPosition;
  double _zoomLevel = AppConstants.defaultZoom;
  MapType _mapType = MapType.normal;

  // Route display
  bool _showRoute = false;
  List<Marker> _routeMarkers = [];

  // Selected marker
  Marker? _selectedMarker;

  // Location state
  LatLng? _currentLocation;
  bool _isLocationEnabled = false;
  bool _isTrackingLocation = false;

  // Getters
  AMapController? get mapController => _mapController;
  LatLng? get cameraPosition => _cameraPosition;
  double get zoomLevel => _zoomLevel;
  MapType get mapType => _mapType;
  bool get showRoute => _showRoute;
  List<Marker> get routeMarkers => List.unmodifiable(_routeMarkers);
  Marker? get selectedMarker => _selectedMarker;
  LatLng? get currentLocation => _currentLocation;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get isTrackingLocation => _isTrackingLocation;

  // Set map controller
  void setMapController(AMapController? controller) {
    _mapController = controller;
    notifyListeners();
  }

  // Move camera to position
  Future<void> moveCamera(LatLng position, {double? zoom}) async {
    await _mapController?.moveCamera(
      CameraUpdate.newLatLngZoom(position, zoom ?? _zoomLevel),
    );
    _cameraPosition = position;
    if (zoom != null) {
      _zoomLevel = zoom;
    }
    notifyListeners();
  }

  // Animate camera to position
  Future<void> animateCamera(LatLng position, {double? zoom}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, zoom ?? _zoomLevel),
    );
    _cameraPosition = position;
    if (zoom != null) {
      _zoomLevel = zoom;
    }
    notifyListeners();
  }

  // Fit bounds to show all markers
  Future<void> fitBounds(List<LatLng> positions) async {
    if (positions.isEmpty) return;

    if (positions.length == 1) {
      await animateCamera(positions.first, zoom: 15.0);
      return;
    }

    // Calculate bounds
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = minLat < pos.latitude ? minLat : pos.latitude;
      maxLat = maxLat > pos.latitude ? maxLat : pos.latitude;
      minLng = minLng < pos.longitude ? minLng : pos.longitude;
      maxLng = maxLng > pos.longitude ? maxLng : pos.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final latDelta = (maxLat - minLat).abs();
    final lngDelta = (maxLng - minLng).abs();

    // Calculate appropriate zoom
    double zoom = 12.0;
    if (latDelta > 0 || lngDelta > 0) {
      final maxDelta = latDelta > lngDelta ? latDelta : lngDelta;
      zoom = _calculateZoomFromDelta(maxDelta);
    }

    await animateCamera(center, zoom: zoom);
  }

  double _calculateZoomFromDelta(double delta) {
    // Approximate zoom level calculation
    if (delta > 10) return 6.0;
    if (delta > 5) return 8.0;
    if (delta > 2) return 10.0;
    if (delta > 1) return 11.0;
    if (delta > 0.5) return 12.0;
    if (delta > 0.1) return 14.0;
    return 16.0;
  }

  // Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (_cameraPosition != null) {
      await moveCamera(_cameraPosition!, zoom: zoom);
    }
  }

  // Set map type
  void setMapType(MapType type) {
    _mapType = type;
    notifyListeners();
  }

  // Toggle route display
  void toggleRoute() {
    _showRoute = !_showRoute;
    notifyListeners();
  }

  void setShowRoute(bool show) {
    _showRoute = show;
    notifyListeners();
  }

  // Set route markers
  void setRouteMarkers(List<Marker> markers) {
    _routeMarkers = markers;
    notifyListeners();
  }

  // Select marker
  void selectMarker(Marker? marker) {
    _selectedMarker = marker;
    notifyListeners();

    // Move camera to marker if provided
    if (marker != null) {
      final position = LatLng(marker.latitude, marker.longitude);
      animateCamera(position, zoom: 15.0);
    }
  }

  // Clear selection
  void clearSelection() {
    _selectedMarker = null;
    notifyListeners();
  }

  // Set current location
  void setCurrentLocation(LatLng? location) {
    _currentLocation = location;
    notifyListeners();
  }

  // Set location enabled
  void setLocationEnabled(bool enabled) {
    _isLocationEnabled = enabled;
    notifyListeners();
  }

  // Set tracking location
  void setTrackingLocation(bool tracking) {
    _isTrackingLocation = tracking;
    notifyListeners();
  }

  // Move to current location
  Future<void> moveToCurrentLocation() async {
    if (_currentLocation != null) {
      await animateCamera(_currentLocation!, zoom: 15.0);
    }
  }

  // Reset map to default position
  Future<void> resetToDefault() async {
    final defaultPosition = LatLng(
      AppConstants.defaultLatitude,
      AppConstants.defaultLongitude,
    );
    await animateCamera(defaultPosition, zoom: AppConstants.defaultZoom);
  }

  // Clear all state
  void clear() {
    _mapController = null;
    _cameraPosition = null;
    _zoomLevel = AppConstants.defaultZoom;
    _mapType = MapType.normal;
    _showRoute = false;
    _routeMarkers = [];
    _selectedMarker = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }
}
