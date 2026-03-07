import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class POI {
  final String id;
  final String name;
  final String address;
  final String? province;
  final String? city;
  final String? district;
  final double latitude;
  final double longitude;
  final String? category;

  const POI({
    required this.id,
    required this.name,
    required this.address,
    this.province,
    this.city,
    this.district,
    required this.latitude,
    required this.longitude,
    this.category,
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as String? ?? '';
    final parts = location.split(',');

    return POI(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ??
          json['pname'] + json['cityname'] + json['adname'],
      province: json['pname'] as String?,
      city: json['cityname'] as String?,
      district: json['adname'] as String?,
      latitude: parts.length > 1 ? double.tryParse(parts[1]) ?? 0 : 0,
      longitude: parts.isNotEmpty ? double.tryParse(parts[0]) ?? 0 : 0,
      category: json['type'] as String?,
    );
  }

  @override
  String toString() => '$name ($address)';
}

class SearchSuggestion {
  final String name;
  final String address;
  final String? district;

  const SearchSuggestion({
    required this.name,
    required this.address,
    this.district,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      name: json['name'] as String? ?? json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      district: json['district'] as String?,
    );
  }
}

class SearchResult {
  final List<POI> pois;
  final int totalCount;
  final bool hasMore;

  const SearchResult({
    required this.pois,
    required this.totalCount,
    required this.hasMore,
  });
}

class SearchService {
  final String _apiKey = AppConstants.amapRestApiKey;
  final String _keywordsUrl = 'https://restapi.amap.com/v3/place/text';
  final String _aroundUrl = 'https://restapi.amap.com/v3/place/around';
  final String _tipsUrl = 'https://restapi.amap.com/v3/assistant/inputtips';

  // Search history
  final List<String> _searchHistory = [];
  static const int _maxHistorySize = 20;

  /// Search POI by keywords
  Future<SearchResult> searchKeywords({
    required String keywords,
    String? city,
    String? category,
    int page = 1,
    int offset = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'key': _apiKey,
        'keywords': keywords,
        'offset': offset.toString(),
        'page': page.toString(),
        'extensions': 'all',
      };

      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['types'] = category;
      }

      final url = Uri.parse(_keywordsUrl).replace(queryParameters: queryParams);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == '1') {
          final pois = (json['pois'] as List?)
                  ?.map((e) => POI.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];

          final count = int.tryParse(json['count'] as String? ?? '0') ?? 0;
          final hasMore = pois.length < count;

          // Add to history
          if (page == 1 && pois.isNotEmpty) {
            _addToHistory(keywords);
          }

          return SearchResult(
            pois: pois,
            totalCount: count,
            hasMore: hasMore,
          );
        }
      }

      return const SearchResult(pois: [], totalCount: 0, hasMore: false);
    } catch (e) {
      print('Error searching keywords: $e');
      return const SearchResult(pois: [], totalCount: 0, hasMore: false);
    }
  }

  /// Search around a location
  Future<SearchResult> searchAround({
    required double latitude,
    required double longitude,
    String? keywords,
    String? type,
    int radius = 1000,
    int page = 1,
    int offset = 20,
  }) async {
    try {
      final location = '$longitude,$latitude';
      final queryParams = <String, String>{
        'key': _apiKey,
        'location': location,
        'radius': radius.toString(),
        'offset': offset.toString(),
        'page': page.toString(),
        'extensions': 'all',
      };

      if (keywords != null && keywords.isNotEmpty) {
        queryParams['keywords'] = keywords;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['types'] = type;
      }

      final url = Uri.parse(_aroundUrl).replace(queryParameters: queryParams);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == '1') {
          final pois = (json['pois'] as List?)
                  ?.map((e) => POI.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];

          final count = int.tryParse(json['count'] as String? ?? '0') ?? 0;
          final hasMore = pois.length < count;

          return SearchResult(
            pois: pois,
            totalCount: count,
            hasMore: hasMore,
          );
        }
      }

      return const SearchResult(pois: [], totalCount: 0, hasMore: false);
    } catch (e) {
      print('Error searching around: $e');
      return const SearchResult(pois: [], totalCount: 0, hasMore: false);
    }
  }

  /// Get search suggestions/autocomplete
  Future<List<SearchSuggestion>> getSuggestions({
    required String keywords,
    String? city,
    String? district,
  }) async {
    if (keywords.isEmpty) {
      return [];
    }

    try {
      final queryParams = <String, String>{
        'key': _apiKey,
        'keywords': keywords,
      };

      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (district != null && district.isNotEmpty) {
        queryParams['district'] = district;
      }

      final url = Uri.parse(_tipsUrl).replace(queryParameters: queryParams);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == '1') {
          return (json['tips'] as List?)
                  ?.map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
        }
      }

      return [];
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  /// Get search history
  List<String> getSearchHistory() {
    return List.unmodifiable(_searchHistory);
  }

  /// Clear search history
  void clearSearchHistory() {
    _searchHistory.clear();
  }

  /// Remove item from history
  void removeFromHistory(String keywords) {
    _searchHistory.remove(keywords);
  }

  void _addToHistory(String keywords) {
    // Remove if already exists
    _searchHistory.remove(keywords);

    // Add to beginning
    _searchHistory.insert(0, keywords);

    // Trim to max size
    while (_searchHistory.length > _maxHistorySize) {
      _searchHistory.removeLast();
    }
  }

  // Common POI categories for search
  static const Map<String, String> poiCategories = {
    '景点': '110000', // Tourist attractions
    '美食': '050000', // Restaurants
    '酒店': '100000', // Hotels
    '购物': '060000', // Shopping
    '交通': '150000', // Transportation
    '医院': '090000', // Hospitals
    '银行': '160000', // Banks
    '加油站': '010100', // Gas stations
  };

  /// Get category code
  static String? getCategoryCode(String category) {
    return poiCategories[category];
  }
}
