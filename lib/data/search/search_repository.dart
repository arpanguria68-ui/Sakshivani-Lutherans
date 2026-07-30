/// Builds and caches the in-memory search indexes for songs and Bible verses,
/// and exposes ranked search over them.
library;

import 'package:flutter/foundation.dart' show compute;

import '../../core/constants/app_constants.dart';
import '../models/bible_verse.dart';
import '../models/song.dart';
import '../repositories/bible_repository.dart';
import '../repositories/content_repository.dart';
import 'search_engine.dart';

/// Building the ~31k-verse index is CPU-heavy (tokenizing + postings lists);
/// running it via [compute] keeps it off the UI isolate so first search /
/// app-start doesn't drop frames.
class _EngineBuildArgs<T> {
  const _EngineBuildArgs(this.docs, this.fields);
  final List<SearchDoc<T>> docs;
  final List<SearchField> fields;
}

SearchEngine<T> _buildEngineIsolate<T>(_EngineBuildArgs<T> args) {
  return SearchEngine<T>.build(args.docs, args.fields);
}

class SearchRepository {
  SearchRepository(this._content, this._bible);

  final ContentRepository _content;
  final BibleRepository _bible;

  final Map<String, SearchEngine<Song>> _songIndex = <String, SearchEngine<Song>>{};
  final Map<String, SearchEngine<BibleVerse>> _verseIndex =
      <String, SearchEngine<BibleVerse>>{};

  // Field order: title, category, reference, lyrics.
  static const List<SearchField> _songFields = <SearchField>[
    SearchField('title', 5.0),
    SearchField('category', 2.0),
    SearchField('reference', 2.5),
    SearchField('lyrics', 1.0),
  ];

  // Field order: book, text.
  static const List<SearchField> _verseFields = <SearchField>[
    SearchField('book', 2.0),
    SearchField('text', 1.0),
  ];

  Future<SearchEngine<Song>> _songs(String book) async {
    final SearchEngine<Song>? cached = _songIndex[book];
    if (cached != null) return cached;
    final List<Song> songs = await _content.getSongs(book: book);
    final SearchEngine<Song> engine = await compute(
      _buildEngineIsolate<Song>,
      _EngineBuildArgs<Song>(
        songs
            .map((Song s) => SearchDoc<Song>(
                  s,
                  <String>[s.title, s.category, s.reference ?? '', s.lyrics],
                ))
            .toList(growable: false),
        _songFields,
      ),
    );
    _songIndex[book] = engine;
    return engine;
  }

  Future<SearchEngine<BibleVerse>> _verses(String language) async {
    final SearchEngine<BibleVerse>? cached = _verseIndex[language];
    if (cached != null) return cached;
    final List<BibleVerse> verses = await _bible.getAllVerses(language);
    final SearchEngine<BibleVerse> engine = await compute(
      _buildEngineIsolate<BibleVerse>,
      _EngineBuildArgs<BibleVerse>(
        verses
            .map((BibleVerse v) =>
                SearchDoc<BibleVerse>(v, <String>[v.book, v.text]))
            .toList(growable: false),
        _verseFields,
      ),
    );
    _verseIndex[language] = engine;
    return engine;
  }

  /// Ranked hymn search within one book (title-weighted, phonetic + translit).
  Future<List<SearchHit<Song>>> searchSongs(
    String query, {
    int limit = 60,
    String book = AppConstants.bookSakshivani,
  }) async {
    if (query.trim().isEmpty) return const <SearchHit<Song>>[];
    return (await _songs(book)).search(query, limit: limit);
  }

  /// Ranked hymn search across both books, merged by score.
  Future<List<SearchHit<Song>>> searchAllSongs(String query, {int limit = 40}) async {
    if (query.trim().isEmpty) return const <SearchHit<Song>>[];
    final List<SearchHit<Song>> a =
        (await _songs(AppConstants.bookSakshivani)).search(query, limit: limit);
    final List<SearchHit<Song>> b =
        (await _songs(AppConstants.bookDurang)).search(query, limit: limit);
    final List<SearchHit<Song>> merged = <SearchHit<Song>>[...a, ...b]
      ..sort((SearchHit<Song> x, SearchHit<Song> y) => y.score.compareTo(x.score));
    return merged.length <= limit ? merged : merged.sublist(0, limit);
  }

  /// Ranked verse search for one language.
  Future<List<SearchHit<BibleVerse>>> searchVerses(
    String language,
    String query, {
    int limit = 60,
  }) async {
    if (query.trim().isEmpty) return const <SearchHit<BibleVerse>>[];
    return (await _verses(language)).search(query, limit: limit);
  }

  /// Ranked verse search across Hindi + English, merged by score.
  Future<List<SearchHit<BibleVerse>>> searchVersesAllLanguages(
    String query, {
    int limit = 60,
  }) async {
    if (query.trim().isEmpty) return const <SearchHit<BibleVerse>>[];
    final List<SearchHit<BibleVerse>> hi =
        await searchVerses('hi', query, limit: limit);
    final List<SearchHit<BibleVerse>> en =
        await searchVerses('en', query, limit: limit);
    final List<SearchHit<BibleVerse>> merged = <SearchHit<BibleVerse>>[...hi, ...en]
      ..sort((SearchHit<BibleVerse> a, SearchHit<BibleVerse> b) =>
          b.score.compareTo(a.score));
    return merged.length <= limit ? merged : merged.sublist(0, limit);
  }

  /// Warm the indexes ahead of first use (e.g. after first frame).
  Future<void> warmUp({bool songs = true, List<String> languages = const <String>['hi']}) async {
    if (songs) await _songs(AppConstants.bookSakshivani);
    for (final String lang in languages) {
      await _verses(lang);
    }
  }
}
