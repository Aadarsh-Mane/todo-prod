import 'package:sqflite/sqflite.dart';
import '../../models/task_model.dart';
import '../../models/tag_model.dart';
import '../../utils/app_logger.dart';
import '../database.dart';

class TaskDao {
  final AppDatabase _db;

  TaskDao(this._db);

  Future<List<TaskModel>> getTasksByListId({
    required int listId,
    String? statusFilter,
    String? sortBy = 'due_date', // 'due_date', 'priority', 'created_at'
    bool ascending = true,
    List<int>? tagIds,
  }) async {
    try {
      final db = await _db.database;
      final orderDir = ascending ? 'ASC' : 'DESC';
      String query = '''
        SELECT t.*, GROUP_CONCAT(tt.tag_id) AS tag_ids
        FROM tasks t
        LEFT JOIN task_tags tt ON t.id = tt.task_id
        WHERE t.list_id = ?
      ''';
      final List<dynamic> args = [listId];

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query += ' AND t.status = ?';
        args.add(statusFilter);
      }

      if (tagIds != null && tagIds.isNotEmpty) {
        final placeholders = tagIds.map((_) => '?').join(',');
        query += ' AND tt.tag_id IN ($placeholders)';
        args.addAll(tagIds.map((id) => id.toString()));
      }

      query += ' GROUP BY t.id ORDER BY t.$sortBy $orderDir NULLS LAST';

      final maps = await db.rawQuery(query, args);

      // Fetch tags separately for full TagModel
      final tasks = <TaskModel>[];
      for (final map in maps) {
        final task = TaskModel.fromMap(map);
        final tagIdsStr = map['tag_ids'] as String?;
        final ids = tagIdsStr
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList() ??
            [];
        final tags = await _getTagsByIds(ids);
        tasks.add(task.copyWith(tags: tags));
      }
      return tasks;
    } catch (e, stackTrace) {
      AppLogger.error(
          'TaskDao.getTasksByListId failed for listId=$listId', e, stackTrace);
      rethrow;
    }
  }

  Future<TaskModel> insertTask(TaskModel task, List<int> tagIds) async {
    try {
      final db = await _db.database;
      final result = await db.transaction((txn) async {
        final id = await txn.insert('tasks', task.toMap());
        for (final tagId in tagIds) {
          await txn.insert(
            'task_tags',
            {'task_id': id, 'tag_id': tagId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        // Re-fetch with tags
        final fullTask = await _getTaskWithTags(txn, id);
        return fullTask;
      });
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
          'TaskDao.insertTask failed for task: ${task.title}', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task, List<int> tagIds) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.update('tasks', task.toMap(),
            where: 'id = ?', whereArgs: [task.id]);
        await txn
            .delete('task_tags', where: 'task_id = ?', whereArgs: [task.id]);
        for (final tagId in tagIds) {
          await txn.insert('task_tags', {'task_id': task.id, 'tag_id': tagId});
        }
      });
      AppLogger.debug('Task updated successfully: ${task.id}');
    } catch (e, stackTrace) {
      AppLogger.error(
          'TaskDao.updateTask failed for taskId: ${task.id}', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final db = await _db.database;
      await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
      AppLogger.debug('Task deleted: $id');
      // Tags cascade
    } catch (e, stackTrace) {
      AppLogger.error(
          'TaskDao.deleteTask failed for taskId: $id', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleTaskStatus(int id, String newStatus) async {
    try {
      final db = await _db.database;
      await db.update(
        'tasks',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.debug('Task status toggled: $id -> $newStatus');
    } catch (e, stackTrace) {
      AppLogger.error(
          'TaskDao.toggleTaskStatus failed for taskId: $id', e, stackTrace);
      rethrow;
    }
  }

  Future<List<TagModel>> getAllTags() async {
    try {
      final db = await _db.database;
      final maps = await db.query('tags', orderBy: 'name');
      return maps.map(TagModel.fromMap).toList();
    } catch (e, stackTrace) {
      AppLogger.error('TaskDao.getAllTags failed', e, stackTrace);
      rethrow;
    }
  }

  Future<List<TagModel>> _getTagsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db.database;
    final placeholders = ids.map((_) => '?').join(',');
    final maps =
        await db.query('tags', where: 'id IN ($placeholders)', whereArgs: ids);
    return maps.map(TagModel.fromMap).toList();
  }

  Future<TaskModel> _getTaskWithTags(Transaction txn, int id) async {
    final map = await txn.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (map.isEmpty) throw Exception('Task not found');
    final task = TaskModel.fromMap(map.first);
    final tagMaps =
        await txn.query('task_tags', where: 'task_id = ?', whereArgs: [id]);
    final tagIds = tagMaps.map((m) => m['tag_id'] as int).toList();
    final tags = await _getTagsByIds(tagIds);
    return task.copyWith(tags: tags);
  }
// Add these to TaskDao class

  Future<Database> getDatabase() async => await _db.database;

  Future<List<TagModel>> getTagsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db.database;
    final placeholders = ids.map((_) => '?').join(',');
    final maps = await db.query(
      'tags',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return maps.map(TagModel.fromMap).toList();
  }

  // Global search support
  Future<List<TaskModel>> searchTasks(String query) async {
    try {
      final db = await _db.database;
      final likeQuery = '%$query%';
      final maps = await db.rawQuery('''
        SELECT t.* FROM tasks t
        WHERE t.title LIKE ? OR t.description LIKE ?
        UNION
        SELECT t.* FROM tasks t
        JOIN task_tags tt ON t.id = tt.task_id
        JOIN tags tg ON tt.tag_id = tg.id
        WHERE tg.name LIKE ?
      ''', [likeQuery, likeQuery, likeQuery]);

      final tasks = <TaskModel>[];
      for (final map in maps) {
        final task = TaskModel.fromMap(map);
        final tagMaps = await db
            .query('task_tags', where: 'task_id = ?', whereArgs: [task.id]);
        final tagIds = tagMaps.map((m) => m['tag_id'] as int).toList();
        final tags = await _getTagsByIds(tagIds);
        tasks.add(task.copyWith(tags: tags));
      }
      return tasks;
    } catch (e, stackTrace) {
      AppLogger.error(
          'TaskDao.searchTasks failed for query: $query', e, stackTrace);
      rethrow;
    }
  }
}
