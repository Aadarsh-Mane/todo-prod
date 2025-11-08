import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/core/core_providers.dart';
import '../../core/database/daos/task_dao.dart';
import '../../core/models/task_model.dart';

class SearchNotifier extends AsyncNotifier<List<TaskModel>> {
  Timer? _debounceTimer;

  @override
  Future<List<TaskModel>> build() async {
    return []; // Initial empty
  }

  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncLoading();
      try {
        final db = ref.read(databaseProvider);
        final results = await TaskDao(db).searchTasks(query.trim());
        state = AsyncData(results);
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    });
  }
}

// Global provider
final searchNotifierProvider =
    AsyncNotifierProvider<SearchNotifier, List<TaskModel>>(() {
  return SearchNotifier();
});
