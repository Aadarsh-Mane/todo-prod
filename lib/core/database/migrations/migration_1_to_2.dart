import 'package:sqflite/sqflite.dart';
import '../../utils/app_logger.dart';

class Migration1To2 {
  Future<void> run(Database db) async {
    AppLogger.info('Starting migration 1 to 2: Adding tags support');
    await db.transaction((txn) async {
      try {
        // Create tags table
        await txn.execute('''
          CREATE TABLE tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            color INTEGER NOT NULL
          );
        ''');
        AppLogger.debug('Tags table created');

        // Create junction table
        await txn.execute('''
          CREATE TABLE task_tags (
            task_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (task_id, tag_id),
            FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
          );
        ''');
        AppLogger.debug('Task-tags junction table created');

        // Indexes
        await txn.execute(
            'CREATE INDEX idx_task_tags_task_id ON task_tags(task_id);');
        AppLogger.debug('Indexes created');

        await txn
            .insert('tags', {'name': 'urgent', 'color': 0xFFFF0000}); // Red
        await txn
            .insert('tags', {'name': 'personal', 'color': 0xFF00FF00}); // Green
        AppLogger.debug('Default tags inserted');

        AppLogger.info('Migration 1 to 2 completed successfully');
      } catch (e, stackTrace) {
        AppLogger.error('Migration 1 to 2 failed', e, stackTrace);
        rethrow; // Rollback transaction on error
      }
    });
  }
}
