class AppConstants {
  // App Info
  static const String appName = 'MapCapture';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'mapcapture.db';
  static const int databaseVersion = 1;

  // Storage
  static const String imagesDir = 'marker_images';
  static const String tempDir = 'temp';

  // Map
  static const double defaultLatitude = 39.9042;  // Beijing
  static const double defaultLongitude = 116.4074;
  static const double defaultZoom = 12.0;

  // Marker Colors
  static const List<String> markerColors = [
    '#FF5722', // Red
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FFC107', // Amber
    '#9C27B0', // Purple
    '#FF9800', // Orange
    '#00BCD4', // Cyan
    '#E91E63', // Pink
  ];

  // Marker Categories
  static const List<String> markerCategories = [
    '景点',
    '美食',
    '酒店',
    '购物',
    '交通',
    '其他',
  ];

  // Pagination
  static const int defaultPageSize = 20;

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;

  // API (Gaode/Amap)
  static const String amapWebApiKey = 'd996d5d90eb3c13a57bcdb5b6501a21e';
  static const String amapRestApiKey = 'd996d5d90eb3c13a57bcdb5b6501a21e';
  static const String amapSecurityJsCode = '67ea1a96de882de569f92f23a01a1e2c';
}

class RoutePaths {
  static const String tripList = '/';
  static const String map = '/map';
  static const String markerDetail = '/marker/:id';
  static const String routePlan = '/route-plan';
}
