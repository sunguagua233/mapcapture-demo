import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    // Delete existing database for development (comment out in production)
    // await deleteDatabase(path);

    final database = await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return database;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables directly (more reliable than loading from asset)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          cover_image_path TEXT,
          start_date INTEGER,
          end_date INTEGER,
          display_order INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS markers (
          id TEXT PRIMARY KEY,
          trip_id TEXT NOT NULL,
          title TEXT NOT NULL,
          address TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          notes TEXT,
          link TEXT,
          category TEXT,
          color TEXT DEFAULT '#FF5722',
          display_order INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS marker_images (
          id TEXT PRIMARY KEY,
          marker_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          display_order INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (marker_id) REFERENCES markers(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_markers_trip_id ON markers(trip_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_marker_images_marker_id ON marker_images(marker_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_trips_display_order ON trips(display_order)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_markers_display_order ON markers(display_order)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades
    if (oldVersion < 2) {
      // Add new fields or tables for version 2
    }
  }

  // Generic CRUD operations

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Batch operations
  Future<void> batch(List<BatchOperation> operations) async {
    final db = await database;
    final batch = db.batch();

    for (final op in operations) {
      switch (op.type) {
        case BatchOperationType.insert:
          batch.insert(op.table, op.data);
          break;
        case BatchOperationType.update:
          batch.update(op.table, op.data, where: op.where, whereArgs: op.whereArgs);
          break;
        case BatchOperationType.delete:
          batch.delete(op.table, where: op.where, whereArgs: op.whereArgs);
          break;
      }
    }

    await batch.commit(noResult: true);
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Raw query support
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }
}

enum BatchOperationType { insert, update, delete }

class BatchOperation {
  final BatchOperationType type;
  final String table;
  final Map<String, dynamic> data;
  final String? where;
  final List<Object?>? whereArgs;

  BatchOperation({
    required this.type,
    required this.table,
    required this.data,
    this.where,
    this.whereArgs,
  });
}
