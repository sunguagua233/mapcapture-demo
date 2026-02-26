/// App-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'MapCapture';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'mapcapture.db';
  static const int databaseVersion = 1;

  // Storage paths
  static const String imagesDir = 'images';
  static const String exportDir = 'exports';

  // Map settings
  static const double defaultMapZoom = 15.0;
  static const double minMapZoom = 3.0;
  static const double maxMapZoom = 18.0;

  // Image settings
  static const int maxImageQuality = 85;
  static const double maxImageWidth = 1920.0;
  static const double maxImageHeight = 1080.0;

  // Cache settings
  static const int maxGeocodeCacheSize = 100;
  static const Duration geocodeCacheExpire = Duration(hours: 24);

  // Pagination
  static const int defaultPageSize = 20;
}
