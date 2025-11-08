import 'package:flutter_test/flutter_test.dart';
import 'package:todo/core/models/task_model.dart';
import 'package:todo/core/models/tag_model.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() {
    setupTestDatabase();
  });

  group('TaskModel - Unit Tests', () {
    test('creates task with required fields', () {
      final task = TaskModel(
        id: 1,
        listId: 1,
        title: 'Test Task',
        priority: 'medium',
        status: 'todo',
        createdAt: DateTime.now(),
        tags: [],
      );

      expect(task.id, 1);
      expect(task.title, 'Test Task');
      expect(task.status, 'todo');
      expect(task.priority, 'medium');
    });

    test('copyWith creates new instance with updated fields', () {
      final task = TaskModel(
        id: 1,
        listId: 1,
        title: 'Original',
        priority: 'low',
        status: 'todo',
        createdAt: DateTime.now(),
        tags: [],
      );

      final updated = task.copyWith(
        title: 'Updated',
        status: 'done',
      );

      expect(updated.title, 'Updated');
      expect(updated.status, 'done');
      expect(updated.id, task.id); // Unchanged fields remain the same
      expect(updated.priority, task.priority);
    });

    test('task with tags', () {
      final tag = TagModel(id: 1, name: 'work', color: 0xFF0000FF);
      final task = TaskModel(
        id: 1,
        listId: 1,
        title: 'Task with tags',
        priority: 'high',
        status: 'todo',
        createdAt: DateTime.now(),
        tags: [tag],
      );

      expect(task.tags.length, 1);
      expect(task.tags.first.name, 'work');
    });

    test('isOverdue returns true for past due dates', () {
      final task = TaskModel(
        id: 1,
        listId: 1,
        title: 'Overdue Task',
        priority: 'high',
        status: 'todo',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        tags: [],
      );

      expect(task.isOverdue, true);
    });

    test('isOverdue returns false for future due dates', () {
      final task = TaskModel(
        id: 1,
        listId: 1,
        title: 'Future Task',
        priority: 'high',
        status: 'todo',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        tags: [],
      );

      expect(task.isOverdue, false);
    });
  });
}
