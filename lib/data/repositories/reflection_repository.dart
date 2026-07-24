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
