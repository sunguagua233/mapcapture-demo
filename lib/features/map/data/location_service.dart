import 'package:mapcapture/core/constants/app_constants.dart';

/// Geocoding result model
class GeocodingResult {
  final String address;
  final String? province;
  final String? city;
  final String? district;
  final DateTime? cachedAt;

  GeocodingResult({
    required this.address,
    this.province,
    this.city,
    this.district,
    this.cachedAt,
  });

  /// Check if cache is expired
  bool get isExpired {
    if (cachedAt == null) return true;
    final age = DateTime.now().difference(cachedAt!);
    return age > AppConstants.geocodeCacheExpire;
  }
}

/// Location service for geocoding operations
///
/// This service handles reverse geocoding (coordinates to address)
/// with built-in caching to avoid excessive API calls.
class LocationService {
  /// Cache for geocoding results
  final Map<String, GeocodingResult> _cache = {};

  /// Simple coordinate key for caching
  String _coordinateKey(double lat, double lng) {
    return '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  }

  /// Reverse geocoding - convert coordinates to address
  ///
  /// Returns cached result if available and not expired.
  /// Otherwise performs geocoding (mock implementation for now).
  Future<GeocodingResult> reverseGeocode(double latitude, double longitude) async {
    final key = _coordinateKey(latitude, longitude);

    // Check cache first
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (!cached.isExpired) {
        return cached;
      }
      _cache.remove(key);
    }

    // Perform geocoding (mock implementation)
    // In production, this would call the actual AMap geocoding API
    final result = await _performReverseGeocode(latitude, longitude);

    // Cache the result
    _cache[key] = result;

    // Clean old cache entries if needed
    _cleanCache();

    return result;
  }

  /// Actual geocoding implementation
  ///
  /// This is a mock implementation. In production, integrate with:
  /// - AMap Web Service API: https://lbs.amap.com/api/webservice/guide/api/georegeo
  /// - Or amap_flutter_location plugin
  Future<GeocodingResult> _performReverseGeocode(
      double latitude, double longitude) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock result based on coordinates
    // In production, replace with actual API call
    return GeocodingResult(
      address: '位置 ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      province: '示例省份',
      city: '示例城市',
      district: '示例区域',
      cachedAt: DateTime.now(),
    );
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
  }

  /// Clean expired cache entries
  void _cleanCache() {
    if (_cache.length <= AppConstants.maxGeocodeCacheSize) return;

    // Remove oldest entries first
    final entries = _cache.entries.toList();
    entries.sort((a, b) {
      final aTime = a.value.cachedAt ?? DateTime(0);
      final bTime = b.value.cachedAt ?? DateTime(0);
      return aTime.compareTo(bTime);
    });

    // Remove oldest 20% of entries
    final removeCount = (entries.length * 0.2).ceil();
    for (int i = 0; i < removeCount; i++) {
      _cache.remove(entries[i].key);
    }
  }

  /// Format coordinates as readable string
  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  /// Calculate distance between two coordinates (in meters)
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  static const double pi = 3.1415926535897932;
}
