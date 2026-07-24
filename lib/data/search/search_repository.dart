/// Builds and caches the in-memory search indexes for songs and Bible verses,
/// and exposes ranked search over them.
library;

import '../models/bible_verse.dart';
import '../models/song.dart';
import '../repositories/bible_repository.dart';
import '../repositories/content_repository.dart';
import 'search_engine.dart';

class SearchRepository {
  SearchRepository(this._content, this._bible);

  final ContentRepository _content;
  final BibleRepository _bible;

  SearchEngine<Song>? _songIndex;
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

  Future<SearchEngine<Song>> _songs() async {
    final SearchEngine<Song>? cached = _songIndex;
    if (cached != null) return cached;
    final List<Song> songs = await _content.getSongs();
    final SearchEngine<Song> engine = SearchEngine<Song>.build(
      songs
          .map((Song s) => SearchDoc<Song>(
                s,
                <String>[s.title, s.category, s.reference ?? '', s.lyrics],
              ))
          .toList(growable: false),
      _songFields,
    );
    _songIndex = engine;
    return engine;
  }

  Future<SearchEngine<BibleVerse>> _verses(String language) async {
    final SearchEngine<BibleVerse>? cached = _verseIndex[language];
    if (cached != null) return cached;
    final List<BibleVerse> verses = await _bible.getAllVerses(language);
    final SearchEngine<BibleVerse> engine = SearchEngine<BibleVerse>.build(
      verses
          .map((BibleVerse v) =>
              SearchDoc<BibleVerse>(v, <String>[v.book, v.text]))
          .toList(growable: false),
      _verseFields,
    );
    _verseIndex[language] = engine;
    return engine;
  }

  /// Ranked hymn search (title-weighted, phonetic + transliteration aware).
  Future<List<SearchHit<Song>>> searchSongs(String query, {int limit = 60}) async {
    if (query.trim().isEmpty) return const <SearchHit<Song>>[];
    return (await _songs()).search(query, limit: limit);
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
    if (songs) await _songs();
    for (final String lang in languages) {
      await _verses(lang);
    }
  }
}
