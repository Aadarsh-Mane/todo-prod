import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/features/lists/list_tile_widget.dart';
import 'package:todo/features/lists/providers/lists_notifier.dart';
import 'package:todo/features/tasks/tasks_screen.dart';
import 'package:todo/shared/widgets/empty_state_widget.dart';
import 'package:todo/shared/widgets/error_widget.dart';
import 'package:todo/shared/widgets/loading_widget.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsNotifierProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('My Lists'),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.pushNamed(context, '/search'),
                tooltip: 'Global Search',
              ),
            ],
          ),
          listsAsync.when(
            loading: () => const SliverFillRemaining(
              child: LoadingWidget(message: 'Loading lists...'),
            ),
            error: (err, st) => SliverFillRemaining(
              child: CustomErrorWidget(
                message: err.toString(),
                onRetry: () =>
                    ref.read(listsNotifierProvider.notifier).refresh(),
              ),
            ),
            data: (lists) => lists.isEmpty
                ? SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.folder_open,
                      title: 'No lists yet',
                      subtitle: 'Create your first list to get started',
                      actionLabel: 'New List',
                      onAction: () => _showCreateDialog(context, ref),
                    ),
                  )
                : SliverReorderableList(
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return ReorderableDragStartListener(
                        key: ValueKey(list.id),
                        index: index,
                        child: ListTileWidget(
                          list: list,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TasksScreen(listId: list.id.toString()),
                            ),
                          ),
                          onRename: (newName) => ref
                              .read(listsNotifierProvider.notifier)
                              .updateList(list.copyWith(name: newName)),
                          onDelete: () {
                            ref
                                .read(listsNotifierProvider.notifier)
                                .deleteList(list.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('List "${list.name}" deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    ref
                                        .read(listsNotifierProvider.notifier)
                                        .createList(list.name);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      // Future: persist order via 'order' column
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        label: const Text('New List'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New List'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter list name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(listsNotifierProvider.notifier).createList(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
