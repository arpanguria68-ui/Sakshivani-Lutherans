import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sakshi_vani/data/local/app_database.dart';
import 'package:sakshi_vani/data/repositories/favorites_repository.dart';
import 'package:sakshi_vani/data/repositories/progress_repository.dart';
import 'package:sakshi_vani/data/repositories/reflection_repository.dart';
import 'package:sakshi_vani/data/repositories/sync_queue_repository.dart';
import 'package:sakshi_vani/services/sync_service.dart';

/// [SyncService]'s Firebase-facing methods all early-return on
/// `firebaseEnabled: false` before touching `FirebaseAuth.instance` /
/// `FirebaseFirestore.instance` — which aren't available in a plain
/// `flutter test` run (no platform channels, no Firebase.initializeApp).
/// That makes the disabled-mode guard itself the thing worth testing here;
/// exercising the enabled path would require mocking the Firebase SDK.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDb;
  late SyncService service;

  setUp(() async {
    final Database db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await AppDatabase.createSchemaForTest(db);
    appDb = AppDatabase.forTest(db);
    final SyncQueueRepository queueRepo = SyncQueueRepository(appDb);

    service = SyncService(
      syncQueueRepository: queueRepo,
      favoritesRepository: FavoritesRepository(appDb, queueRepo),
      reflectionRepository: ReflectionRepository(appDb, queueRepo),
      progressRepository: ProgressRepository(appDb, queueRepo),
      firebaseEnabled: false,
    );
  });

  tearDown(() async {
    await appDb.db.close();
  });

  test('flushPendingQueue is a no-op when Firebase is disabled', () async {
    await service.flushPendingQueue();
  });

  test('pullFromCloud is a no-op when Firebase is disabled', () async {
    await service.pullFromCloud();
  });

  test('deleteCloudUserData is a no-op when Firebase is disabled', () async {
    await service.deleteCloudUserData();
  });
}
