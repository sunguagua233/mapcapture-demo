import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class GeocodingResult {
  final String address;
  final String? province;
  final String? city;
  final String? district;
  final String? township;
  final String? street;
  final String? streetNumber;

  const GeocodingResult({
    required this.address,
    this.province,
    this.city,
    this.district,
    this.township,
    this.street,
    this.streetNumber,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    final addressComponent = json['addressComponent'] as Map<String, dynamic>?;

    return GeocodingResult(
      address: json['formatted_address'] as String? ?? '',
      province: addressComponent?['province'] as String?,
      city: addressComponent?['city'] as String?,
      district: addressComponent?['district'] as String?,
      township: addressComponent?['township'] as String?,
      street: addressComponent?['street'] as String?,
      streetNumber: addressComponent?['streetNumber'] as String?,
    );
  }

  @override
  String toString() => address;
}

class GeocodingService {
  final String _apiKey = AppConstants.amapRestApiKey;
  final String _baseUrl = 'https://restapi.amap.com/v3/geocode/regeo';

  // Result cache
  final Map<String, GeocodingResult> _cache = {};

  /// Get address from coordinates (reverse geocoding)
  Future<GeocodingResult?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // Create cache key
    final cacheKey = '${latitude}_$longitude';

    // Check cache
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final location = '$longitude,$latitude';
      final url = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
        'location': location,
        'extensions': 'base',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == '1' && json['regeocode'] != null) {
          final result = GeocodingResult.fromJson(json['regeocode']);

          // Cache result
          _cache[cacheKey] = result;

          return result;
        }
      }

      return null;
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return null;
    }
  }

  /// Batch reverse geocoding
  Future<Map<String, GeocodingResult>> batchGetAddresses(
    Map<String, LatLng> coordinates,
  ) async {
    final results = <String, GeocodingResult>{};

    for (final entry in coordinates.entries) {
      final key = entry.key;
      final latLng = entry.value;

      final result = await getAddressFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (result != null) {
        results[key] = result;
      }
    }

    return results;
  }

  /// Get coordinates from address (geocoding)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse('https://restapi.amap.com/v3/geocode/geo')
          .replace(queryParameters: {
        'key': _apiKey,
        'address': address,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == '1' && json['geocodes'] != null) {
          final geocodes = json['geocodes'] as List;
          if (geocodes.isNotEmpty) {
            final location = geocodes[0]['location'] as String;
            final parts = location.split(',');
            if (parts.length == 2) {
              return LatLng(
                double.parse(parts[1]),
                double.parse(parts[0]),
              );
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error in geocoding: $e');
      return null;
    }
  }

  /// Convert coordinates between different coordinate systems
  /// For example: GPS to Amap coordinates
  LatLng convertCoordinates(
    double latitude,
    double longitude, {
    CoordinateSystem from = CoordinateSystem.gps,
    CoordinateSystem to = CoordinateSystem.amap,
  }) {
    if (from == to) {
      return LatLng(latitude, longitude);
    }

    // GPS to Amap conversion (simplified)
    if (from == CoordinateSystem.gps && to == CoordinateSystem.amap) {
      return _gpsToAmap(latitude, longitude);
    }

    return LatLng(latitude, longitude);
  }

  LatLng _gpsToAmap(double lat, double lng) {
    // This is a simplified conversion
    // For production use, use the official conversion API
    const double pi = 3.1415926535897932384626;
    final double a = 6378245.0;
    final double ee = 0.00669342162296594323;

    double transformLat(double x, double y) {
      double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * (x.abs()).sqrt();
      ret += (20.0 * (1.0 - (2.0 * x * pi).sin()).sin() + 20.0 * (1.0 - (2.0 * y * pi).sin()).sin()) * 2.0 / 3.0;
      ret += (20.0 * (1.0 - (y * pi).sin()).sin() + 40.0 * (1.0 - (y * pi / 30.0).sin()).sin()) * 2.0 / 3.0;
      ret += (160.0 * (1.0 - (y * pi / 12.0).sin()).sin() * 2.0 / 3.0;
      return ret;
    }

    double transformLng(double x, double y) {
      double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * (x.abs()).sqrt();
      ret += (20.0 * (1.0 - (2.0 * x * pi).sin()).sin() + 20.0 * (1.0 - (2.0 * y * pi).sin()).sin()) * 2.0 / 3.0;
      ret += (20.0 * (1.0 - (x * pi).sin()).sin() + 40.0 * (1.0 - (x * pi / 30.0).sin()).sin()) * 2.0 / 3.0;
      ret += (150.0 * (1.0 - (x * pi / 12.0).sin()).sin() + 300.0 * (1.0 - (x * pi / 30.0).sin()).sin()) * 2.0 / 3.0;
      return ret;
    }

    double dLat = transformLat(lng - 105.0, lat - 35.0);
    double dLng = transformLng(lng - 105.0, lat - 35.0);
    final double radLat = lat / 180.0 * pi;
    double magic = (radLat.sin() * radLat.sin());
    magic = 1 - ee * magic;
    final double sqrtMagic = magic.sqrt();
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (a / sqrtMagic * (radLat.cos()) * pi);

    return LatLng(lat + dLat, lng + dLng);
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Get cache size
  int get cacheSize => _cache.length;
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => '$latitude, $longitude';
}

enum CoordinateSystem {
  gps,
  amap,
  baidu,
}
