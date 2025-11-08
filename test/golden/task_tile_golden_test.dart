import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:todo/core/models/tag_model.dart';
import 'package:todo/core/models/task_model.dart';
import 'package:todo/features/tasks/task_tile_widget.dart';

void main() {
  // Load the default Roboto font for golden consistency
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens(
      'TaskTileWidget - renders correctly (todo, high priority, tags, due soon)',
      (WidgetTester tester) async {
    final task = TaskModel(
      id: 1,
      listId: 1,
      title: 'Buy groceries',
      description: 'Milk, eggs, bread',
      dueDate: DateTime.now().add(const Duration(hours: 24)),
      priority: 'high',
      status: 'todo',
      createdAt: DateTime.now(),
      tags: [
        TagModel(id: 1, name: 'shopping', color: 0xFFFF0000),
        TagModel(id: 2, name: 'urgent', color: 0xFFFFA500),
      ],
    );

    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400, // Simulates phone width
              child: TaskTileWidget(
                task: task,
                onToggle: (_) {},
                onDelete: () {},
                onEdit: () {},
              ),
            ),
          ),
        ),
      ),
      surfaceSize: const Size(400, 180),
    );

    await screenMatchesGolden(tester, 'task_tile_todo_high_tags_due_soon');
  });

  testGoldens('TaskTileWidget - done state with strikethrough',
      (WidgetTester tester) async {
    final task = TaskModel(
      id: 2,
      listId: 1,
      title: 'Completed task',
      status: 'done',
      priority: 'low',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidgetBuilder(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: TaskTileWidget(
                task: task,
                onToggle: (_) {},
                onDelete: () {},
                onEdit: () {},
              ),
            ),
          ),
        ),
      ),
      surfaceSize: const Size(400, 120),
    );

    await screenMatchesGolden(tester, 'task_tile_done_strikethrough');
  });
}
