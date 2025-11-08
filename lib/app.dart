import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/lists/lists_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/tasks/task_editor_screen.dart';
import 'search/global_search_screen.dart';
import 'shared/themes/theme_provider.dart'; // For themeNotifier
import 'shared/widgets/error_widget.dart'; // Custom error UI

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Task Manager',
      themeMode: themeMode,
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const ListsScreen(),
      routes: {
        '/lists': (context) => const ListsScreen(),
        '/search': (context) => const GlobalSearchScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/tasks/') == true) {
          final listId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => TasksScreen(listId: listId),
          );
        }
        if (settings.name?.startsWith('/edit/') == true) {
          final parts = settings.name!.split('/');
          final taskId = parts.last;
          // Extract listId from arguments or default to empty string
          final args = settings.arguments as Map<String, dynamic>?;
          final listId = args?['listId'] as int? ?? 0;
          return MaterialPageRoute(
            builder: (context) =>
                TaskEditorScreen(taskId: taskId, listId: listId),
          );
        }
        return null;
      },
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) =>
            CustomErrorWidget(
              message: 'An unexpected error occurred. Please restart the app.',
              onRetry: () => runApp(const ProviderScope(
                  child:
                      MyApp())), // Simple restart; in prod, could reset providers
            );
        return child!;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
