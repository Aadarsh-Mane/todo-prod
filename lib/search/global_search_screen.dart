import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/features/tasks/task_editor_screen.dart';
import 'package:todo/features/tasks/task_tile_widget.dart';
import 'package:todo/search/search_providers.dart';
import 'package:todo/shared/widgets/empty_state_widget.dart';
import 'package:todo/shared/widgets/error_widget.dart';
import 'package:todo/shared/widgets/loading_widget.dart';
import '../../core/models/task_model.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchNotifierProvider.notifier).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search tasks by title or tag...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchNotifierProvider.notifier).search('');
                    },
                  )
                : null,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: searchAsync.when(
        data: (results) {
          if (_searchController.text.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.search,
                title: 'Search all tasks',
                subtitle:
                    'Type a keyword or tag to find tasks across all lists',
              ),
            );
          }
          if (results.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.sentiment_dissatisfied,
                title: 'No results found',
                subtitle: 'Try different keywords or tags',
              ),
            );
          }

          // Group by list name for better UX
          final grouped = <String, List<TaskModel>>{};
          for (final task in results) {
            final listName =
                'List ID: ${task.listId}'; // In prod, join with list name via repo
            grouped.putIfAbsent(listName, () => []).add(task);
          }

          return ListView.builder(
            itemCount: grouped.keys.length,
            itemBuilder: (context, index) {
              final listName = grouped.keys.elementAt(index);
              final tasks = grouped[listName]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      listName,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...tasks.map((task) => TaskTileWidget(
                        task: task,
                        onToggle: (_) {}, // Read-only in search
                        onDelete: () {}, // Not allowed here
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskEditorScreen(
                                taskId: task.id.toString(),
                                listId: task.listId,
                              ),
                            ),
                          );
                        },
                      )),
                ],
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Searching...'),
        error: (err, st) => CustomErrorWidget(
          message: err.toString(),
          onRetry: () => ref
              .read(searchNotifierProvider.notifier)
              .search(_searchController.text),
        ),
      ),
    );
  }
}
