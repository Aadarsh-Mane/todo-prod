import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/core/core_providers.dart';
import '../../../core/database/daos/task_dao.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/tag_model.dart';

class TasksRepository {
  final TaskDao _taskDao;

  TasksRepository(this._taskDao);

  Future<List<TaskModel>> getTasks({
    required int listId,
    String? statusFilter,
    String sortBy = 'due_date',
    bool ascending = true,
    List<int>? tagIds,
  }) async {
    try {
      return await _taskDao.getTasksByListId(
        listId: listId,
        statusFilter: statusFilter,
        sortBy: sortBy,
        ascending: ascending,
        tagIds: tagIds,
      );
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<TaskModel> createTask(TaskModel task, List<String> tagNames) async {
    if (!task.isValid) {
      throw Exception('Task title is required and due date must be valid');
    }
    try {
      final allTags = await _taskDao.getAllTags();
      final tagIds = <int>[];
      for (final name in tagNames) {
        var tag = allTags.firstWhere(
            (t) => t.name.toLowerCase() == name.toLowerCase(),
            orElse: () => TagModel(id: -1, name: '', color: 0xFF000000));
        if (tag.id == -1) {
          // Create new tag (random color for demo; in prod, let user choose)
          final db = await _taskDao.getDatabase();
          final newId =
              await db.insert('tags', {'name': name, 'color': _randomColor()});
          tag = TagModel(id: newId, name: name, color: _randomColor());
        }
        tagIds.add(tag.id);
      }
      final created = await _taskDao.insertTask(
          task.copyWith(createdAt: DateTime.now()), tagIds);
      return created.copyWith(tags: await _taskDao.getTagsByIds(tagIds));
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<void> updateTask(TaskModel task, List<String> tagNames) async {
    if (!task.isValid) {
      throw Exception('Invalid task data');
    }
    try {
      final allTags = await _taskDao.getAllTags();
      final tagIds = <int>[];
      for (final name in tagNames) {
        var tag = allTags.firstWhere(
            (t) => t.name.toLowerCase() == name.toLowerCase(),
            orElse: () => TagModel(id: -1, name: '', color: 0xFF000000));
        if (tag.id == -1) {
          final db = await _taskDao.getDatabase();
          final newId =
              await db.insert('tags', {'name': name, 'color': _randomColor()});
          tag = TagModel(id: newId, name: name, color: _randomColor());
        }
        tagIds.add(tag.id);
      }
      await _taskDao.updateTask(task, tagIds);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _taskDao.deleteTask(id);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> toggleComplete(int id, bool isDone) async {
    try {
      await _taskDao.toggleTaskStatus(id, isDone ? 'done' : 'todo');
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  Future<List<TagModel>> getAllTags() async {
    try {
      return await _taskDao.getAllTags();
    } catch (e) {
      throw Exception('Failed to load tags: $e');
    }
  }

  int _randomColor() {
    final colors = [
      0xFFFF0000,
      0xFF00FF00,
      0xFF0000FF,
      0xFFFFFF00,
      0xFFFF00FF,
      0xFF00FFFF
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }
}

// Scoped provider per listId
final tasksRepositoryProvider =
    Provider.family<TasksRepository, int>((ref, listId) {
  final db = ref.watch(databaseProvider);
  return TasksRepository(TaskDao(db));
});
