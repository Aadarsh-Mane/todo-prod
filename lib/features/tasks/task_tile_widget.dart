import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task_model.dart';

class TaskTileWidget extends ConsumerWidget {
  final TaskModel task;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskTileWidget({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = task.status == 'done';
    final priorityColor = task.priority == 'high'
        ? Colors.red
        : task.priority == 'medium'
            ? Colors.orange
            : Colors.green;

    return Dismissible(
      key: ValueKey(task.id),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        } else {
          onEdit();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDone ? Theme.of(context).colorScheme.surfaceVariant : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: isDone,
            onChanged: (val) => onToggle(val ?? false),
            semanticLabel: 'Mark task as ${isDone ? 'todo' : 'done'}',
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? Theme.of(context).disabledColor : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Text(task.description!,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              if (task.dueDate != null)
                Row(
                  children: [
                    Icon(
                      task.isOverdue ? Icons.warning : Icons.schedule,
                      size: 16,
                      color: task.isOverdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate!.toLocal().toString().split(' ').first,
                      style:
                          TextStyle(color: task.isOverdue ? Colors.red : null),
                    ),
                    if (task.isDueSoon && !task.isOverdue)
                      const Text(' (Due soon)',
                          style: TextStyle(color: Colors.orange)),
                  ],
                ),
              if (task.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: task.tags
                      .map((tag) => Chip(
                            label: Text(tag.name,
                                style: const TextStyle(fontSize: 10)),
                            backgroundColor: tag.uiColor.withOpacity(0.2),
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}
