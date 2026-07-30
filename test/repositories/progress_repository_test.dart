import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sakshi_vani/data/local/app_database.dart';
import 'package:sakshi_vani/data/repositories/progress_repository.dart';
import 'package:sakshi_vani/data/repositories/sync_queue_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDb;
  late SyncQueueRepository queueRepo;
  late ProgressRepository repo;

  setUp(() async {
    final Database db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.createSchemaForTest(db);
    appDb = AppDatabase.forTest(db);
    queueRepo = SyncQueueRepository(appDb);
    repo = ProgressRepository(appDb, queueRepo);
  });

  tearDown(() async {
    await appDb.db.close();
  });

  test('upsertPrayerLog inserts a new day then updates it in place', () async {
    final DateTime date = DateTime(2026, 1, 1);
    await repo.upsertPrayerLog(date: date, count: 2, notes: 'morning');

    final prayerLog = await repo.getPrayerLogForDate(date);
    expect(prayerLog?.count, 2);
    expect(prayerLog?.notes, 'morning');

    await repo.upsertPrayerLog(date: date, count: 5, notes: 'evening');
    final updated = await repo.getPrayerLogForDate(date);
    expect(updated?.count, 5);
    expect(updated?.notes, 'evening');
    expect(updated?.id, prayerLog?.id, reason: 'update should reuse the same row');

    final pending = await queueRepo.pending();
    expect(pending.length, 2, reason: 'both the insert and the update enqueue a sync item');
    expect(pending.every((item) => item.type == 'prayer_log_upsert'), isTrue);
  });

  test('getProgressStats computes a streak of consecutive days ending today', () async {
    final DateTime today = DateTime.now();
    await repo.upsertPrayerLog(date: today, count: 1, notes: '');
    await repo.upsertPrayerLog(date: today.subtract(const Duration(days: 1)), count: 1, notes: '');
    // Gap here breaks the streak.
    await repo.upsertPrayerLog(date: today.subtract(const Duration(days: 3)), count: 2, notes: '');

    final stats = await repo.getProgressStats();
    expect(stats.currentStreak, 2);
    expect(stats.totalPrayerDays, 3);
    expect(stats.totalPrayerCount, 4);
  });

  test('getProgressStats is zeroed out with no logs', () async {
    final stats = await repo.getProgressStats();
    expect(stats.currentStreak, 0);
    expect(stats.totalPrayerCount, 0);
    expect(stats.totalPrayerDays, 0);
  });

  test('mergeFromCloud inserts a new date without enqueuing a sync push', () async {
    await repo.mergeFromCloud(<Map<String, dynamic>>[
      <String, dynamic>{
        'date_iso': '2026-02-01',
        'count': 3,
        'notes': 'from cloud',
        'updated_at': '2026-02-01T00:00:00.000Z',
      },
    ]);

    final prayerLog = await repo.getPrayerLogForDate(DateTime(2026, 2, 1));
    expect(prayerLog?.count, 3);
    expect(prayerLog?.notes, 'from cloud');
    expect(await queueRepo.pending(), isEmpty);
  });

  test('mergeFromCloud overwrites an existing local row (cloud wins)', () async {
    final DateTime date = DateTime(2026, 3, 1);
    await repo.upsertPrayerLog(date: date, count: 1, notes: 'local');

    await repo.mergeFromCloud(<Map<String, dynamic>>[
      <String, dynamic>{
        'date_iso': '2026-03-01',
        'count': 9,
        'notes': 'cloud wins',
        'updated_at': '2026-03-01T00:00:00.000Z',
      },
    ]);

    final prayerLog = await repo.getPrayerLogForDate(date);
    expect(prayerLog?.count, 9);
    expect(prayerLog?.notes, 'cloud wins');
  });

  test('mergeFromCloud skips malformed rows without a valid date', () async {
    await repo.mergeFromCloud(<Map<String, dynamic>>[
      <String, dynamic>{'count': 3, 'notes': 'no date'},
      <String, dynamic>{'date_iso': 'not-a-date', 'count': 3, 'notes': 'bad date'},
    ]);
    final stats = await repo.getProgressStats();
    expect(stats.totalPrayerDays, 0);
  });
}
