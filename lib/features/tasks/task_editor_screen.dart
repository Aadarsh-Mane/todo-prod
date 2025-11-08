import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/features/lists/providers/tasks_notifier.dart';
import 'package:todo/features/lists/repository/tasks_repository.dart';
import '../../core/models/task_model.dart';
import '../../core/models/tag_model.dart';
import '../../core/utils/constants.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final String? taskId; // Null for create, id for edit
  final int listId; // Required for create/edit context

  const TaskEditorScreen({super.key, this.taskId, required this.listId});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagController;
  DateTime? _dueDate;
  String _priority = 'medium';
  String _status = 'todo';
  final List<String> _selectedTags = [];
  List<TagModel> _allTags = [];
  bool _isLoading = false;
  TaskModel? _existingTask;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _tagController = TextEditingController();
    if (widget.taskId != null) {
      _loadExistingTask();
    }
    _loadTags();
  }

  Future<void> _loadExistingTask() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await ref
          .read(tasksRepositoryProvider(widget.listId))
          .getTasks(listId: widget.listId);
      _existingTask = tasks.firstWhere((t) => t.id.toString() == widget.taskId);
      _titleController.text = _existingTask!.title;
      _descController.text = _existingTask!.description ?? '';
      _dueDate = _existingTask!.dueDate;
      _priority = _existingTask!.priority;
      _status = _existingTask!.status;
      _selectedTags.addAll(_existingTask!.tags.map((t) => t.name));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load task: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTags() async {
    try {
      _allTags =
          await ref.read(tasksRepositoryProvider(widget.listId)).getAllTags();
      setState(() {});
    } catch (e) {
      // Silent; tags optional
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(tasksNotifierProvider(widget.listId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskId == null ? 'New Task' : 'Edit Task'),
        actions: [
          if (widget.taskId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Task?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await notifier.deleteTask(int.parse(widget.taskId!));
                  if (mounted) Navigator.pop(context);
                }
              },
              tooltip: 'Delete Task',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.trim().isEmpty ? kTitleRequiredError : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_dueDate == null
                          ? 'No due date'
                          : 'Due: ${_dueDate!.toLocal().toString().split(' ').first}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                    ),
                    if (_dueDate != null)
                      TextButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear due date'),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: kPriorities
                          .map((p) => DropdownMenuItem(
                              value: p, child: Text(p.toUpperCase())))
                          .toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: kStatuses
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                    const SizedBox(height: 16),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _allTags
                            .map((t) => t.name)
                            .where((name) => name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()))
                            .toList();
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        _tagController = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Add tag',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final tag = controller.text.trim();
                                if (tag.isNotEmpty &&
                                    !_selectedTags.contains(tag)) {
                                  setState(() => _selectedTags.add(tag));
                                  controller.clear();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _selectedTags.map((tag) {
                        final tagModel = _allTags.firstWhere(
                            (t) => t.name == tag,
                            orElse: () =>
                                TagModel(id: -1, name: tag, color: 0xFF888888));
                        return Chip(
                          label: Text(tag),
                          backgroundColor: tagModel.uiColor.withOpacity(0.2),
                          onDeleted: () =>
                              setState(() => _selectedTags.remove(tag)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                final task = TaskModel(
                                  id: _existingTask?.id ?? 0, // 0 for new
                                  listId: widget.listId,
                                  title: _titleController.text.trim(),
                                  description:
                                      _descController.text.trim().isEmpty
                                          ? null
                                          : _descController.text.trim(),
                                  dueDate: _dueDate,
                                  priority: _priority,
                                  status: _status,
                                  createdAt: _existingTask?.createdAt ??
                                      DateTime.now(),
                                  tags: [], // Populated in repo
                                );
                                try {
                                  if (widget.taskId == null) {
                                    await notifier.createTask(
                                        task, _selectedTags);
                                  } else {
                                    await notifier.updateTask(
                                        task, _selectedTags);
                                  }
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())));
                                } finally {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(widget.taskId == null
                              ? 'Create Task'
                              : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
