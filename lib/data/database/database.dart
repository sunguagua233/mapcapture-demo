import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

/// Part directive for generated code
part 'database.drift.dart';

/// AppDatabase - Main database class for MapCapture
///
/// This class manages all database operations using Drift ORM.
/// It supports SQLite for mobile platforms with automatic schema management.
class AppDatabase extends _$AppDatabase {
  /// Singleton instance
  static AppDatabase? _instance;

  /// Get singleton instance
  factory AppDatabase.getInstance() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  /// Private constructor
  AppDatabase._internal() : super(_openConnection());

  /// Database schema version
  @override
  int get schemaVersion => 1;

  /// Migration handler
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
        if (from < 2) {
          // Example migration for version 2
        }
      },
      beforeOpen: (OpeningDetails details) async {
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Open database connection
  static QueryExecutor _openConnection() {
    // For development, use in-memory database
    // In production, this will be replaced with file-based storage
    return NativeDatabase.createInBackground(
      File(':memory:'),
    );
  }

  /// Initialize database with file storage
  ///
  /// Call this method to set up file-based storage instead of in-memory.
  static Future<QueryExecutor> openFileConnection() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbDir.path, 'mapcapture.db'));
    return NativeDatabase.createInBackground(file);
  }
}

/// Database connection for dependency injection
final databaseProvider = AppDatabase.getInstance();
