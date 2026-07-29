import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../models/reflection_entry.dart';
import 'sync_queue_repository.dart';

class ReflectionRepository {
  ReflectionRepository(this._database, this._syncQueueRepository);

  final AppDatabase _database;
  final SyncQueueRepository _syncQueueRepository;
  final Uuid _uuid = const Uuid();

  Future<List<ReflectionEntry>> getReflections({int limit = 50}) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      'reflections',
      orderBy: 'date_iso DESC, updated_at DESC',
      limit: limit,
    );
    return rows.map(ReflectionEntry.fromMap).toList(growable: false);
  }

  Future<void> addReflection({
    required String text,
    required String verse,
    required bool isPrivate,
  }) async {
    final DateTime now = DateTime.now();
    final ReflectionEntry entry = ReflectionEntry(
      id: _uuid.v4(),
      text: text,
      verse: verse,
      dateIso: now.toIso8601String(),
      isPrivate: isPrivate,
      synced: false,
      updatedAt: now.toUtc().toIso8601String(),
    );

    await _database.db.insert('reflections', entry.toMap());
    await _syncQueueRepository.enqueue(
      type: 'reflection_upsert',
      payload: <String, dynamic>{
        'id': entry.id,
        'text': entry.text,
        'verse': entry.verse,
        'date_iso': entry.dateIso,
        'is_private': entry.isPrivate,
        'updated_at': entry.updatedAt,
      },
    );
  }

  /// Merge reflections pulled from Firestore into the local DB ("cloud
  /// wins" — overwrites any local row with the same id). Does not
  /// re-enqueue a sync push; this data already came from the cloud.
  Future<void> mergeFromCloud(List<Map<String, dynamic>> items) async {
    for (final Map<String, dynamic> item in items) {
      final String id = item['id'] as String? ?? '';
      if (id.isEmpty) continue;
      await _database.db.insert(
        'reflections',
        <String, Object?>{
          'id': id,
          'text': item['text'] as String? ?? '',
          'verse': item['verse'] as String? ?? '',
          'date_iso': item['date_iso'] as String? ?? '',
          'is_private': (item['is_private'] as bool? ?? true) ? 1 : 0,
          'synced': 1,
          'updated_at': item['updated_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteReflection(String id) async {
    await _database.db.delete('reflections', where: 'id = ?', whereArgs: <Object?>[id]);
    await _syncQueueRepository.enqueue(
      type: 'reflection_delete',
      payload: <String, dynamic>{
        'id': id,
      },
    );
  }
}
