import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/core/core_providers.dart';
import '../../../core/database/daos/list_dao.dart';
import '../../../core/models/list_model.dart';
import '../../../core/utils/constants.dart';

class ListsRepository {
  final ListDao _listDao;

  ListsRepository(this._listDao);

  Future<List<ListModel>> getAllLists() async {
    try {
      final lists = await _listDao.getAllLists();
      // Ensure default Inbox exists
      if (lists.isEmpty) {
        final inbox = await createList(kDefaultListName);
        return [inbox];
      }
      return lists;
    } catch (e) {
      throw Exception('Failed to load lists: $e');
    }
  }

  Future<ListModel> createList(String name) async {
    if (!name.trim().isNotEmpty || name.trim().length > 100) {
      throw Exception('List name must be 1-100 characters');
    }
    try {
      // Check uniqueness (case-insensitive)
      final existing = await _listDao.getAllLists();
      if (existing
          .any((l) => l.name.toLowerCase() == name.trim().toLowerCase())) {
        throw Exception('A list with this name already exists');
      }
      return await _listDao.insertList(name);
    } catch (e) {
      throw Exception('Failed to create list: $e');
    }
  }

  Future<void> updateList(ListModel list) async {
    if (!list.isValid) {
      throw Exception('Invalid list name');
    }
    try {
      // Re-check uniqueness on rename
      final all = await _listDao.getAllLists();
      final conflict = all.any((l) =>
          l.id != list.id && l.name.toLowerCase() == list.name.toLowerCase());
      if (conflict) {
        throw Exception('Another list with this name exists');
      }
      await _listDao.updateList(list);
    } catch (e) {
      throw Exception('Failed to update list: $e');
    }
  }

  Future<void> deleteList(int id) async {
    try {
      await _listDao.deleteList(id);
    } catch (e) {
      throw Exception('Failed to delete list: $e');
    }
  }
}

// Riverpod provider for dependency injection
final listsRepositoryProvider = Provider<ListsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ListsRepository(ListDao(db));
});
