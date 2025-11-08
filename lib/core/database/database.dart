import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/constants.dart';
import '../utils/app_logger.dart';
import 'migrations/migration_1_to_2.dart'; // Example migration

class AppDatabase {
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, kDatabaseName);
      AppLogger.info('Initializing database at: $path');

      // Try to open the database
      return await openDatabase(
        path,
        version: kDatabaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          // Verify tables exist
          final tables = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='tasks'");
          if (tables.isEmpty) {
            // Database exists but tables are missing, recreate it
            AppLogger.warning(
                'Database corrupted, tables missing. Recreating database...');
            await db.close();
            await deleteDatabase(path);
            throw Exception('Database corrupted, recreating...');
          }
          AppLogger.info('Database opened successfully');
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Database init error', e, stackTrace);
      // If database is corrupted, try to delete and recreate
      try {
        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, kDatabaseName);
        AppLogger.info('Attempting to recreate database');
        await deleteDatabase(path);

        // Try again after deletion
        return await openDatabase(
          path,
          version: kDatabaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      } catch (e2, stackTrace2) {
        AppLogger.fatal('Database recreation failed', e2, stackTrace2);
        rethrow;
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating database tables (version: $version)');

    // Load schema from asset file
    final schemaSql = await rootBundle.loadString('assets/db/schema.sql');

    // Execute schema SQL - split by semicolons and execute each statement
    final statements = schemaSql.split(';').where((s) => s.trim().isNotEmpty);
    for (final statement in statements) {
      await db.execute(statement.trim());
    }

    // Insert default list if needed
    await db.insert('lists',
        {'name': 'Inbox', 'created_at': DateTime.now().toIso8601String()});

    AppLogger.info('Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info(
        'Upgrading database from version $oldVersion to $newVersion');
    if (oldVersion < 2) {
      await Migration1To2().run(db); // Add tags table, migrate tasks
    }
    // Add more migrations as needed
    AppLogger.info('Database upgrade completed');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      AppLogger.info('Closing database connection');
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabaseFile() async {
    try {
      final path = join(await getDatabasesPath(), kDatabaseName);
      AppLogger.warning('Deleting database file: $path');
      await deleteDatabase(path);
      AppLogger.info('Database file deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete database', e, stackTrace);
    }
  }
}
