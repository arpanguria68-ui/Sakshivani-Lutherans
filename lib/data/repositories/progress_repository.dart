import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/prayer_log.dart';
import 'sync_queue_repository.dart';

class ProgressStats {
  const ProgressStats({
    required this.currentStreak,
    required this.totalPrayerCount,
    required this.totalPrayerDays,
  });

  final int currentStreak;
  final int totalPrayerCount;
  final int totalPrayerDays;
}

class ProgressRepository {
  ProgressRepository(this._database, this._syncQueueRepository);

  final AppDatabase _database;
  final SyncQueueRepository _syncQueueRepository;

  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  Future<PrayerLog?> getPrayerLogForDate(DateTime date) async {
    final String isoDate = _iso.format(date);
    final List<Map<String, Object?>> rows = await _database.db.query(
      'prayer_logs',
      where: 'date_iso = ?',
      whereArgs: <Object?>[isoDate],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return PrayerLog.fromMap(rows.first);
  }

  Future<void> upsertPrayerLog({
    required DateTime date,
    required int count,
    required String notes,
  }) async {
    final String isoDate = _iso.format(date);
    final String now = DateTime.now().toUtc().toIso8601String();

    final PrayerLog? existing = await getPrayerLogForDate(date);
    if (existing == null) {
      await _database.db.insert(
        'prayer_logs',
        <String, Object?>{
          'date_iso': isoDate,
          'count': count,
          'notes': notes,
          'synced': 0,
          'updated_at': now,
        },
      );
    } else {
      await _database.db.update(
        'prayer_logs',
        <String, Object?>{
          'count': count,
          'notes': notes,
          'synced': 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: <Object?>[existing.id],
      );
    }

    await _syncQueueRepository.enqueue(
      type: 'prayer_log_upsert',
      payload: <String, dynamic>{
        'date_iso': isoDate,
        'count': count,
        'notes': notes,
        'updated_at': now,
      },
    );
  }

  /// Merge prayer logs pulled from Firestore into the local DB ("cloud
  /// wins" on overlapping dates). `prayer_logs` has no unique index on
  /// `date_iso`, so this looks up by date first rather than using
  /// [ConflictAlgorithm.replace]. Does not re-enqueue a sync push.
  Future<void> mergeFromCloud(List<Map<String, dynamic>> items) async {
    for (final Map<String, dynamic> item in items) {
      final String? isoDate = item['date_iso'] as String?;
      if (isoDate == null || isoDate.isEmpty) continue;
      final DateTime? date = DateTime.tryParse(isoDate);
      if (date == null) continue;

      final int count = (item['count'] as num?)?.toInt() ?? 0;
      final String notes = item['notes'] as String? ?? '';
      final String updatedAt =
          item['updated_at'] as String? ?? DateTime.now().toUtc().toIso8601String();

      final PrayerLog? existing = await getPrayerLogForDate(date);
      if (existing == null) {
        await _database.db.insert('prayer_logs', <String, Object?>{
          'date_iso': isoDate,
          'count': count,
          'notes': notes,
          'synced': 1,
          'updated_at': updatedAt,
        });
      } else {
        await _database.db.update(
          'prayer_logs',
          <String, Object?>{
            'count': count,
            'notes': notes,
            'synced': 1,
            'updated_at': updatedAt,
          },
          where: 'id = ?',
          whereArgs: <Object?>[existing.id],
        );
      }
    }
  }

  Future<List<PrayerLog>> getRecentPrayerLogs({int limit = 30}) async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      'prayer_logs',
      orderBy: 'date_iso DESC',
      limit: limit,
    );
    return rows.map(PrayerLog.fromMap).toList(growable: false);
  }

  Future<ProgressStats> getProgressStats() async {
    final List<Map<String, Object?>> rows = await _database.db.query(
      'prayer_logs',
      orderBy: 'date_iso DESC',
      limit: 365,
    );
    if (rows.isEmpty) {
      return const ProgressStats(currentStreak: 0, totalPrayerCount: 0, totalPrayerDays: 0);
    }

    final List<PrayerLog> logs = rows.map(PrayerLog.fromMap).toList(growable: false);
    final int totalCount = logs.fold<int>(0, (int prev, PrayerLog e) => prev + e.count);

    int streak = 0;
    DateTime cursor = DateTime.now();
    final Set<String> daySet = logs.map((PrayerLog e) => e.dateIso).toSet();
    while (daySet.contains(_iso.format(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return ProgressStats(
      currentStreak: streak,
      totalPrayerCount: totalCount,
      totalPrayerDays: logs.length,
    );
  }
}
