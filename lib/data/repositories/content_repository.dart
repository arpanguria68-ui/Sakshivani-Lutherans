import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../local/app_database.dart';
import '../models/catechism_chapter.dart';
import '../models/quiz_question.dart';
import '../models/song.dart';

class ContentRepository {
  ContentRepository(this._database);

  final AppDatabase _database;
  List<Song>? _durangCache;

  /// Load the bundled Mundari Durang Puthi songbook (660 hymns), cached.
  Future<List<Song>> _loadDurang() async {
    final List<Song>? cached = _durangCache;
    if (cached != null) return cached;
    final String raw = await rootBundle.loadString(AppConstants.durangAssetPath);
    final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
    final List<Song> songs = decoded
        .whereType<Map<String, dynamic>>()
        .map(Song.fromDurangJson)
        .toList(growable: false);
    _durangCache = songs;
    return songs;
  }

  Future<List<Song>> getSongs({
    String query = '',
    String book = AppConstants.bookSakshivani,
  }) async {
    final String sanitized = query.trim();

    if (book == AppConstants.bookDurang) {
      final List<Song> all = await _loadDurang();
      if (sanitized.isEmpty) return all;
      final String q = sanitized.toLowerCase();
      return all
          .where((Song s) =>
              s.title.toLowerCase().contains(q) || s.lyrics.toLowerCase().contains(q))
          .toList(growable: false);
    }

    final List<Map<String, Object?>> rows;
    if (sanitized.isEmpty) {
      rows = await _database.songsDb.query(
        'songs',
        columns: <String>['song_id', 'title', 'lyrics', 'category', 'reference'],
        orderBy: 'song_id ASC',
      );
    } else {
      rows = await _database.songsDb.query(
        'songs',
        columns: <String>['song_id', 'title', 'lyrics', 'category', 'reference'],
        where: 'title LIKE ? OR lyrics LIKE ? OR category LIKE ? OR reference LIKE ?',
        whereArgs: <Object?>[
          '%$sanitized%',
          '%$sanitized%',
          '%$sanitized%',
          '%$sanitized%',
        ],
        orderBy: 'song_id ASC',
      );
    }

    return rows.map(Song.fromDb).toList();
  }

  Future<Song?> getSongById(int id, {String book = AppConstants.bookSakshivani}) async {
    if (book == AppConstants.bookDurang) {
      final List<Song> all = await _loadDurang();
      for (final Song s in all) {
        if (s.id == id) return s;
      }
      return null;
    }

    final List<Map<String, Object?>> rows = await _database.songsDb.query(
      'songs',
      columns: <String>['song_id', 'title', 'lyrics', 'category', 'reference'],
      where: 'song_id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }
    return Song.fromDb(rows.first);
  }

  Future<List<CatechismChapter>> getCatechismChapters() async {
    final String raw = await rootBundle.loadString(AppConstants.catechismAssetPath);
    final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CatechismChapter.fromJson)
        .toList(growable: false);
  }

  Future<List<QuizQuestion>> getQuizQuestions() async {
    final String raw = await rootBundle.loadString(AppConstants.quizAssetPath);
    final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestion.fromJson)
        .toList(growable: false);
  }
}
