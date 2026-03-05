# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (development/demo mode)
flutter run

# Run with specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome

# Generate code (required after modifying Drift tables, Riverpod providers, or models)
flutter pub run build_runner build

# Delete generated files before regenerating (use when build_runner has issues)
flutter pub run build_runner clean

# Watch mode for code generation (regenerates on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Project Architecture

**MapCapture** is a travel route planning Flutter app with map marking functionality, using Clean Architecture + Feature-First structure.

### Tech Stack
- **State Management**: Riverpod (with code generation via `@riverpod` annotations)
- **Database**: Drift ORM (SQLite) with singleton pattern
- **Map**: AMap (高德地图/amap_flutter_map) for China region
- **Router**: go_router

### Layer Structure

```
lib/
├── core/                   # Shared infrastructure
│   ├── constants/          # AppConstants with app-wide settings
│   ├── theme/              # App theme configuration
│   ├── router/             # Route configuration
│   └── utils/              # Utility functions
├── data/                   # Data layer
│   ├── database/           # Drift database (tables.dart, database.dart)
│   ├── models/             # Data models and entities
│   ├── repositories/       # Repository implementations
│   ├── providers/          # Riverpod providers (databaseProvider, etc.)
│   └── services/           # External service integrations
├── features/               # Feature modules (trip, marker, map, media, view)
│   └── [feature]/
│       ├── data/           # Data-specific implementations
│       ├── domain/         # Business logic, controllers
│       └── presentation/   # UI screens and widgets
└── demo/                   # Demo/prototype code (currently active in main.dart)
```

### Database Schema

**Core Tables** (defined in `lib/data/database/tables.dart`):
- **Trips** (`@DataClassName('Trip')`): Trip metadata, cover image, date range, displayOrder
- **Markers** (`@DataClassName('TripMarker')`): Map points with lat/lng, title, address, notes, link, displayOrder
- **Images** (`@DataClassName('MarkerImage')`): Image file paths per marker, displayOrder

**Key Relationships**: Trips → Markers (cascade delete) → Images (cascade delete)

**Important**: All tables use `displayOrder` for drag-and-drop sorting functionality.

### Riverpod Patterns

- Providers use code generation: `@riverpod class MyController extends _$MyController`
- Access providers: `ref.read(providerProvider)`, `ref.watch(providerProvider)`
- State classes typically include `copyWith` method for immutable updates
- Database singleton: `AppDatabase.getInstance()`

### Code Generation Requirements

After modifying any of the following, run `build_runner`:
- Drift tables (`tables.dart`) - generates `.drift.dart` files
- Riverpod controllers with `@riverpod` - generates `.g.dart` files
- Any file with `part 'filename.drift.dart'` or `part 'filename.g.dart'` directives

### Current Entry Point

`lib/main.dart` currently launches the demo (`MapCaptureDemo` from `lib/demo/main_demo.dart`). The production implementation is in `lib/features/`.

### AMap (高德地图) Integration

The app uses AMap Flutter plugins for map display and reverse geocoding. When developing map features:
- Coordinates: Uses standard lat/lng
- Reverse geocoding: Auto-fills marker titles with address from clicked location
- Default center: Beijing (39.9042, 116.4074)

### Feature Modules

- **trip**: Trip CRUD, cover image management
- **marker**: Map marker creation, editing, sorting
- **map**: Map display, camera control, marker placement
- **media**: Image handling (multi-upload, storage)
- **view**: View switching (card list ↔ grid thumbnails), drag-sort

### Web Demo

The `web_demo/` directory contains a separate HTML/CSS/JS prototype used for early development and reference. It is independent of the Flutter app and uses localStorage for data persistence.
