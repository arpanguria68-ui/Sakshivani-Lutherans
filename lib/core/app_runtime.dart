import '../data/local/app_database.dart';

class AppRuntime {
  AppRuntime._();

  static AppDatabase? _database;
  static bool firebaseEnabled = false;

  static AppDatabase get database {
    final AppDatabase? db = _database;
    if (db == null) {
      throw StateError('AppRuntime.database is not initialized.');
    }
    return db;
  }

  static void setDatabase(AppDatabase database) {
    _database = database;
  }
}
