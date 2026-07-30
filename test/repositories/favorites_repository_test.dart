import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sakshi_vani/data/local/app_database.dart';
import 'package:sakshi_vani/data/repositories/favorites_repository.dart';
import 'package:sakshi_vani/data/repositories/sync_queue_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDb;
  late SyncQueueRepository queueRepo;
  late FavoritesRepository repo;

  setUp(() async {
    final Database db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.createSchemaForTest(db);
    appDb = AppDatabase.forTest(db);
    queueRepo = SyncQueueRepository(appDb);
    repo = FavoritesRepository(appDb, queueRepo);
  });

  tearDown(() async {
    await appDb.db.close();
  });

  test('toggleFavorite adds then removes the same item', () async {
    expect(await repo.isFavorite(itemType: 'song', itemRef: '12'), isFalse);

    await repo.toggleFavorite(itemType: 'song', itemRef: '12');
    expect(await repo.isFavorite(itemType: 'song', itemRef: '12'), isTrue);

    await repo.toggleFavorite(itemType: 'song', itemRef: '12');
    expect(await repo.isFavorite(itemType: 'song', itemRef: '12'), isFalse);

    final pending = await queueRepo.pending();
    expect(pending.map((item) => item.type).toList(), <String>['favorite_upsert', 'favorite_delete']);
  });

  test('listFavoritesByType only returns matching type, newest first', () async {
    await repo.toggleFavorite(itemType: 'song', itemRef: '1');
    await repo.toggleFavorite(itemType: 'verse', itemRef: 'John 3:16');
    await repo.toggleFavorite(itemType: 'song', itemRef: '2');

    final songs = await repo.listFavoritesByType('song');
    expect(songs.length, 2);
    expect(songs.first.itemRef, '2', reason: 'most recently created should sort first');

    final verses = await repo.listFavoritesByType('verse');
    expect(verses.length, 1);
    expect(verses.single.itemRef, 'John 3:16');
  });

  test('duplicate toggles do not create duplicate rows', () async {
    await repo.toggleFavorite(itemType: 'song', itemRef: '7');
    expect(await repo.isFavorite(itemType: 'song', itemRef: '7'), isTrue);

    // Toggling again removes it (there is no "add twice" path in this API).
    await repo.toggleFavorite(itemType: 'song', itemRef: '7');
    final songs = await repo.listFavoritesByType('song');
    expect(songs, isEmpty);
  });

  test('mergeFromCloud adds a favorite absent locally, skips one already present', () async {
    await repo.toggleFavorite(itemType: 'song', itemRef: '5');
    final int pendingBefore = (await queueRepo.pending()).length;

    await repo.mergeFromCloud(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'cloud-1',
        'item_type': 'song',
        'item_ref': '5',
        'created_at': '2026-01-01T00:00:00.000Z',
      },
      <String, dynamic>{
        'id': 'cloud-2',
        'item_type': 'verse',
        'item_ref': 'Psalm 23:1',
        'created_at': '2026-01-02T00:00:00.000Z',
      },
    ]);

    final songs = await repo.listFavoritesByType('song');
    expect(songs.length, 1, reason: 'already-favorited item should not be duplicated');

    final verses = await repo.listFavoritesByType('verse');
    expect(verses.single.itemRef, 'Psalm 23:1');
    expect(
      (await queueRepo.pending()).length,
      pendingBefore,
      reason: 'a cloud merge must not re-enqueue a push',
    );
  });

  test('mergeFromCloud ignores rows missing item_type or item_ref', () async {
    await repo.mergeFromCloud(<Map<String, dynamic>>[
      <String, dynamic>{'item_type': '', 'item_ref': 'x'},
      <String, dynamic>{'item_type': 'song'},
    ]);
    expect(await repo.listFavoritesByType('song'), isEmpty);
  });
}
