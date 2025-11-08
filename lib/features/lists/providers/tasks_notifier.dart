import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task_model.dart';
import '../repository/tasks_repository.dart';

class TasksNotifier extends FamilyAsyncNotifier<List<TaskModel>, int> {
  late final TasksRepository _repository;

  @override
  Future<List<TaskModel>> build(int arg) async {
    _repository = ref.read(tasksRepositoryProvider(arg));
    return await _loadTasks();
  }

  int get listId => arg;

  Future<List<TaskModel>> _loadTasks({
    String? statusFilter,
    String sortBy = 'due_date',
    bool ascending = true,
    List<int>? tagIds,
  }) async {
    return await _repository.getTasks(
      listId: listId,
      statusFilter: statusFilter,
      sortBy: sortBy,
      ascending: ascending,
      tagIds: tagIds,
    );
  }

  Future<void> createTask(TaskModel task, List<String> tagNames) async {
    state = const AsyncLoading();
    try {
      final newTask = await _repository.createTask(task, tagNames);
      state = AsyncData([...state.value ?? [], newTask]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateTask(TaskModel task, List<String> tagNames) async {
    final oldState = state.value ?? [];
    state = AsyncData([
      for (final t in oldState)
        if (t.id == task.id) task else t
    ]);
    try {
      await _repository.updateTask(task, tagNames);
    } catch (e, st) {
      state = AsyncData(oldState); // Rollback on error
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTask(int id) async {
    final oldState = state.value ?? [];
    state = AsyncData(oldState.where((t) => t.id != id).toList());
    try {
      await _repository.deleteTask(id);
    } catch (e, st) {
      state = AsyncData(oldState); // Rollback
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleComplete(int id, bool isDone) async {
    final oldState = state.value ?? [];
    final updatedTasks = oldState.map((t) {
      if (t.id == id) {
        return t.copyWith(status: isDone ? 'done' : 'todo');
      }
      return t;
    }).toList();
    state = AsyncData(updatedTasks);
    try {
      await _repository.toggleComplete(id, isDone);
    } catch (e, st) {
      state = AsyncData(oldState); // Rollback
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh({
    String? statusFilter,
    String sortBy = 'due_date',
    bool ascending = true,
    List<int>? tagIds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadTasks(
          statusFilter: statusFilter,
          sortBy: sortBy,
          ascending: ascending,
          tagIds: tagIds,
        ));
  }
}

// Family provider (scoped by listId)
final tasksNotifierProvider =
    AsyncNotifierProvider.family<TasksNotifier, List<TaskModel>, int>(
  TasksNotifier.new,
);
