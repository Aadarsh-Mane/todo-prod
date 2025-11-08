import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/list_model.dart';
import '../repository/lists_repository.dart';

class ListsNotifier extends AsyncNotifier<List<ListModel>> {
  late final ListsRepository _repository = ref.read(listsRepositoryProvider);

  @override
  Future<List<ListModel>> build() async {
    return await _repository.getAllLists();
  }

  Future<void> createList(String name) async {
    state = const AsyncLoading();
    try {
      final newList = await _repository.createList(name);
      state = AsyncData([...state.value ?? [], newList]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateList(ListModel updatedList) async {
    try {
      await _repository.updateList(updatedList);
      state = AsyncData([
        for (final list in state.value ?? [])
          if (list.id == updatedList.id) updatedList else list
      ]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteList(int id) async {
    try {
      await _repository.deleteList(id);
      state = AsyncData((state.value ?? []).where((l) => l.id != id).toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Helper to refresh full list (e.g., after navigation back)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getAllLists());
  }
}

// Riverpod provider
final listsNotifierProvider =
    AsyncNotifierProvider<ListsNotifier, List<ListModel>>(() {
  return ListsNotifier();
});
