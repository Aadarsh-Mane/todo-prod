import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/features/lists/providers/tasks_notifier.dart';
import 'package:todo/features/tasks/task_editor_screen.dart';
import 'package:todo/features/tasks/task_tile_widget.dart';
import 'package:todo/shared/widgets/empty_state_widget.dart';
import 'package:todo/shared/widgets/error_widget.dart';
import 'package:todo/shared/widgets/loading_widget.dart';
import '../../core/models/task_model.dart';
import '../../core/utils/constants.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final String listId;
  const TasksScreen({super.key, required this.listId});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String statusFilter = 'all';
  String sortBy = 'due_date';
  bool ascending = true;
  final Set<int> selectedTagIds = {};

  String _formatSortLabel(String sortBy) {
    switch (sortBy) {
      case 'due_date':
        return 'Due Date';
      case 'priority':
        return 'Priority';
      case 'created_at':
        return 'Created Date';
      default:
        return sortBy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync =
        ref.watch(tasksNotifierProvider(int.parse(widget.listId)));
    final notifier =
        ref.read(tasksNotifierProvider(int.parse(widget.listId)).notifier);

    ref.listen(tasksNotifierProvider(int.parse(widget.listId)), (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error.toString())));
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(
          statusFilter: statusFilter == 'all' ? null : statusFilter,
          sortBy: sortBy,
          ascending: ascending,
          tagIds: selectedTagIds.isEmpty ? null : selectedTagIds.toList(),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              title: Text('Tasks in List ${widget.listId}'),
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context)),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() => statusFilter = value);
                    notifier.refresh(
                        statusFilter: value == 'all' ? null : value);
                  },
                  itemBuilder: (_) => ['all', ...kStatuses]
                      .map((s) =>
                          PopupMenuItem(value: s, child: Text(s.toUpperCase())))
                      .toList(),
                  child: Chip(
                      label: Text('Filter: ${statusFilter.toUpperCase()}')),
                ),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() => sortBy = value);
                    notifier.refresh(sortBy: value);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'due_date', child: Text('Sort by Due Date')),
                    const PopupMenuItem(
                        value: 'priority', child: Text('Sort by Priority')),
                    const PopupMenuItem(
                        value: 'created_at',
                        child: Text('Sort by Created Date')),
                  ],
                  child: Chip(label: Text('Sort: ${_formatSortLabel(sortBy)}')),
                ),
              ],
            ),
            tasksAsync.when(
              loading: () => const SliverFillRemaining(
                  child: LoadingWidget(message: 'Loading tasks...')),
              error: (err, st) => SliverFillRemaining(
                child: CustomErrorWidget(
                  message: err.toString(),
                  onRetry: () => notifier.refresh(),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.checklist,
                      title: 'No tasks yet',
                      subtitle: 'Add your first task to this list',
                      actionLabel: 'New Task',
                      onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TaskEditorScreen(
                                    listId: int.parse(widget.listId),
                                  ))),
                    ),
                  );
                }

                final dueSoon = tasks.where((t) => t.isDueSoon).toList();
                final overdue = tasks.where((t) => t.isOverdue).toList();
                final others =
                    tasks.where((t) => !t.isDueSoon && !t.isOverdue).toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      List<TaskModel> sectionTasks = [];
                      String sectionTitle = '';
                      if (index == 0 && dueSoon.isNotEmpty) {
                        sectionTasks = dueSoon;
                        sectionTitle = 'Due Soon (next 48h)';
                      } else if ((index == 0 || index == dueSoon.length + 1) &&
                          overdue.isNotEmpty) {
                        sectionTasks = overdue;
                        sectionTitle = 'Overdue';
                      } else if (index == dueSoon.length + overdue.length + 2) {
                        sectionTasks = others;
                        sectionTitle = 'Others';
                      }

                      if (sectionTitle.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(sectionTitle,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                            ),
                            ...sectionTasks.map((task) => TaskTileWidget(
                                  task: task,
                                  onToggle: (done) =>
                                      notifier.toggleComplete(task.id, done),
                                  onDelete: () => notifier.deleteTask(task.id),
                                  onEdit: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskEditorScreen(
                                        taskId: task.id.toString(),
                                        listId: int.parse(
                                            widget.listId), // ADD THIS
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: (dueSoon.isNotEmpty ? dueSoon.length + 1 : 0) +
                        (overdue.isNotEmpty ? overdue.length + 1 : 0) +
                        (others.isNotEmpty ? others.length + 1 : 0),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskEditorScreen(listId: int.parse(widget.listId)),
          ),
        ),
        label: const Text('New Task'),
        icon: const Icon(Icons.add_task),
      ),
    );
  }
}
