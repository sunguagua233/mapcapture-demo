import 'package:drift/drift.dart';

/// Part directive for generated code
part 'tables.drift.dart';

/// Trips table - stores travel trip information
@DataClassName('Trip')
class Trips extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Trip name
  TextColumn get name => text()();

  /// Cover image path (nullable)
  TextColumn get coverImagePath => text().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Trip start date (nullable)
  DateTimeColumn get startDate => dateTime().nullable()();

  /// Trip end date (nullable)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Display order for sorting
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
}

/// Markers table - stores map marker information
@DataClassName('TripMarker')
class Markers extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to trips table
  IntColumn get tripId => integer().references(Trips, #id, onDelete: KeyAction.cascade)();

  /// Marker title
  TextColumn get title => text()();

  /// Address from reverse geocoding
  TextColumn get address => text()();

  /// Latitude coordinate
  RealColumn get latitude => real()();

  /// Longitude coordinate
  RealColumn get longitude => real()();

  /// User notes (nullable)
  TextColumn get notes => text().nullable()();

  /// Reference link (nullable)
  TextColumn get link => text().nullable()();

  /// Display order for sorting
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Images table - stores marker image information
@DataClassName('MarkerImage')
class Images extends Table {
  /// Primary key
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to markers table
  IntColumn get markerId => integer().references(Markers, #id, onDelete: KeyAction.cascade)();

  /// Image file path
  TextColumn get filePath => text()();

  /// Display order for sorting
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
