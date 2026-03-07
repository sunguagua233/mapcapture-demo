# MapCapture Flutter

A Flutter application for capturing and managing travel locations and routes.

## Features

- **Trip Management**: Create, edit, and delete travel trips
- **Map Integration**: Amap (高德地图) integration for displaying markers
- **Marker Management**: Add, edit, and delete location markers
- **Image Support**: Attach photos to markers
- **Route Planning**: Visualize routes with drag-to-reorder functionality
- **Reverse Geocoding**: Automatic address lookup from coordinates
- **POI Search**: Search for places using Amap API

## Architecture

```
lib/
├── core/           # Core utilities and constants
├── data/           # Data layer (models, database, repositories)
├── providers/      # State management with Provider
├── services/       # Business logic services
├── screens/        # UI screens
└── widgets/        # Reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Configuration

1. **Get Amap API Keys**
   - Register at [Amap Open Platform](https://lbs.amap.com/)
   - Create an application and get API keys for:
     - Android
     - iOS
     - Web API (for geocoding)

2. **Configure API Keys**

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <meta-data
       android:name="com.amap.api.v2.apikey"
       android:value="YOUR_AMAP_ANDROID_KEY" />
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>AMapApiKey</key>
   <string>YOUR_AMAP_IOS_KEY</string>
   ```

   **App Constants** (`lib/core/constants/app_constants.dart`):
   ```dart
   static const String amapRestApiKey = 'YOUR_AMAP_REST_KEY';
   ```

### Installation

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Building

### Android
```bash
flutter build apk
# or
flutter build appbundle
```

### iOS
```bash
flutter build ios
```

## Dependencies

- `provider` - State management
- `sqflite` - SQLite database
- `amap_flutter_map` - Amap map widget
- `image_picker` - Image selection
- `permission_handler` - Runtime permissions

## License

MIT
