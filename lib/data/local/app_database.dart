import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

class AppDatabase {
  AppDatabase._(this.db);

  static AppDatabase? _instance;

  final Database db;

  static Future<AppDatabase> open() async {
    if (_instance != null) {
      return _instance!;
    }

    final String songsPath = await _ensureSongsDb();
    final Database songsDb = await openDatabase(songsPath, readOnly: true);

    final Directory dir = await getApplicationDocumentsDirectory();
    final String appDbPath = p.join(dir.path, 'sakshi_vani_app.db');

    final Database appDb = await openDatabase(
      appDbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE prayer_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date_iso TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT '',
            synced INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reflections (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            verse TEXT NOT NULL,
            date_iso TEXT NOT NULL,
            is_private INTEGER NOT NULL DEFAULT 1,
            synced INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retries INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE favorites (
            id TEXT PRIMARY KEY,
            item_type TEXT NOT NULL,
            item_ref TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    await appDb.execute("ATTACH DATABASE '$songsPath' AS songsdb");
    _instance = AppDatabase._(appDb);
    _instance!._songsDb = songsDb;
    return _instance!;
  }

  Database? _songsDb;

  Database get songsDb {
    final Database? db = _songsDb;
    if (db == null) {
      throw StateError('songsDb not initialized');
    }
    return db;
  }

  Future<void> close() async {
    await db.close();
    if (_songsDb != null) {
      await _songsDb!.close();
      _songsDb = null;
    }
    _instance = null;
  }

  static Future<String> _ensureSongsDb() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String songsPath = p.join(dir.path, 'Sakshivani_Unicode_Clean.db');
    final File file = File(songsPath);
    if (await file.exists()) {
      return songsPath;
    }

    final ByteData data = await rootBundle.load(AppConstants.songsDbAssetPath);
    final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await file.writeAsBytes(bytes, flush: true);
    return songsPath;
  }
}
