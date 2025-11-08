import 'package:sqflite/sqflite.dart';
import '../../models/list_model.dart';
import '../../utils/app_logger.dart';
import '../database.dart';

class ListDao {
  final AppDatabase _db;

  ListDao(this._db);

  Future<List<ListModel>> getAllLists() async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'lists',
        orderBy: 'created_at DESC',
      );
      AppLogger.debug('Retrieved ${maps.length} lists');
      return maps.map(ListModel.fromMap).toList();
    } catch (e, stackTrace) {
      AppLogger.error('ListDao.getAllLists failed', e, stackTrace);
      rethrow;
    }
  }

  Future<ListModel> insertList(String name) async {
    try {
      final db = await _db.database;
      final id = await db.insert(
        'lists',
        {
          'name': name.trim(),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      AppLogger.info('List created: $name (id: $id)');
      return ListModel(
        id: id,
        name: name.trim(),
        createdAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'ListDao.insertList failed for name: $name', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateList(ListModel list) async {
    try {
      final db = await _db.database;
      await db.update(
        'lists',
        list.toMap(),
        where: 'id = ?',
        whereArgs: [list.id],
      );
      AppLogger.debug('List updated: ${list.id}');
    } catch (e, stackTrace) {
      AppLogger.error(
          'ListDao.updateList failed for listId: ${list.id}', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteList(int id) async {
    try {
      final db = await _db.database;
      await db.delete(
        'lists',
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.info('List deleted: $id (tasks auto-deleted via CASCADE)');
      // Tasks auto-deleted via ON DELETE CASCADE
    } catch (e, stackTrace) {
      AppLogger.error(
          'ListDao.deleteList failed for listId: $id', e, stackTrace);
      rethrow;
    }
  }

  Future<ListModel?> getListById(int id) async {
    try {
      final db = await _db.database;
      final maps = await db.query(
        'lists',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return ListModel.fromMap(maps.first);
    } catch (e, stackTrace) {
      AppLogger.error(
          'ListDao.getListById failed for listId: $id', e, stackTrace);
      rethrow;
    }
  }
}
