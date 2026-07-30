import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../local/app_database.dart';

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.retries,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final String createdAt;
  final int retries;

  factory SyncQueueItem.fromMap(Map<String, Object?> map) {
    final String rawPayload = map['payload'] as String? ?? '{}';
    return SyncQueueItem(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      payload: json.decode(rawPayload) as Map<String, dynamic>,
      createdAt: map['created_at'] as String? ?? '',
      retries: (map['retries'] as num?)?.toInt() ?? 0,
    );
  }
}

class SyncQueueRepository {
  SyncQueueRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<void> enqueue({required String type, required Map<String, dynamic> payload}) async {
    final DateTime now = DateTime.now().toUtc();
    await _database.db.insert(
      'sync_queue',
      <String, Object?>{
        'id': _uuid.v4(),
        'type': type,
        'payload': json.encode(payload),
        'created_at': now.toIso8601String(),
        'retries': 0,
      },
    );
  }

  Future<List<SyncQueueItem>> pending({int limit = 50}) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(SyncQueueItem.fromMap).toList(growable: false);
  }

  Future<void> removeById(String id) async {
    await _database.db.delete('sync_queue', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> incrementRetry(String id) async {
    await _database.db.rawUpdate('UPDATE sync_queue SET retries = retries + 1 WHERE id = ?', <Object?>[id]);
  }
}
