import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../models/favorite_item.dart';
import 'sync_queue_repository.dart';

class FavoritesRepository {
  FavoritesRepository(this._database, this._syncQueueRepository);

  final AppDatabase _database;
  final SyncQueueRepository _syncQueueRepository;
  final Uuid _uuid = const Uuid();

  Future<List<FavoriteItem>> listFavoritesByType(String itemType) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      'favorites',
      where: 'item_type = ?',
      whereArgs: <Object?>[itemType],
      orderBy: 'created_at DESC',
    );
    return rows.map(FavoriteItem.fromMap).toList(growable: false);
  }

  Future<bool> isFavorite({required String itemType, required String itemRef}) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      'favorites',
      where: 'item_type = ? AND item_ref = ?',
      whereArgs: <Object?>[itemType, itemRef],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> toggleFavorite({required String itemType, required String itemRef}) async {
    final List<Map<String, Object?>> existingRows = await _database.db.query(
      'favorites',
      columns: <String>['id', 'item_type', 'item_ref'],
      where: 'item_type = ? AND item_ref = ?',
      whereArgs: <Object?>[itemType, itemRef],
      limit: 1,
    );

    if (existingRows.isNotEmpty) {
      final String existingId = existingRows.first['id'] as String? ?? '';
      await _database.db.delete(
        'favorites',
        where: 'item_type = ? AND item_ref = ?',
        whereArgs: <Object?>[itemType, itemRef],
      );
      await _syncQueueRepository.enqueue(
        type: 'favorite_delete',
        payload: <String, dynamic>{
          'id': existingId,
          'item_type': itemType,
          'item_ref': itemRef,
        },
      );
      return;
    }

    final FavoriteItem item = FavoriteItem(
      id: _uuid.v4(),
      itemType: itemType,
      itemRef: itemRef,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _database.db.insert('favorites', item.toMap());
    await _syncQueueRepository.enqueue(
      type: 'favorite_upsert',
      payload: <String, dynamic>{
        'id': item.id,
        'item_type': item.itemType,
        'item_ref': item.itemRef,
        'created_at': item.createdAt,
      },
    );
  }

  /// Merge favorites pulled from Firestore into the local DB — restores
  /// favorites on a new device/reinstall. Skips ones already present
  /// locally; does not re-enqueue a sync push.
  Future<void> mergeFromCloud(List<Map<String, dynamic>> items) async {
    for (final Map<String, dynamic> item in items) {
      final String itemType = item['item_type'] as String? ?? '';
      final String itemRef = item['item_ref'] as String? ?? '';
      if (itemType.isEmpty || itemRef.isEmpty) continue;
      if (await isFavorite(itemType: itemType, itemRef: itemRef)) continue;
      await _database.db.insert(
        'favorites',
        <String, Object?>{
          'id': item['id'] as String? ?? _uuid.v4(),
          'item_type': itemType,
          'item_ref': itemRef,
          'created_at':
              item['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
