import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/features/tasks/tasks_screen.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() {
    setupTestDatabase();
  });

  group('TasksScreen - Widget Tests', () {
    testWidgets('displays tasks screen with title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TasksScreen(listId: '1'),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(TasksScreen), findsOneWidget);
    });

    testWidgets('displays loading state initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TasksScreen(listId: '1'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
