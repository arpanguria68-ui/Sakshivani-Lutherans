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

  Future<List<Song>> getSongs({String query = ''}) async {
    final String sanitized = query.trim();
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

  Future<Song?> getSongById(int id) async {
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
