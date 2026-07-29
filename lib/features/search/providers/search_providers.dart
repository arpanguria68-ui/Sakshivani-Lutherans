/// Riverpod providers backing the ranked search bars (songs + Bible).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/bible_verse.dart';
import '../../../data/models/song.dart';
import '../../../data/search/search_engine.dart';

/// Key for a per-book song search.
typedef SongQuery = ({String book, String query});

/// Ranked hymn search within one book.
final songSearchProvider =
    FutureProvider.family<List<SearchHit<Song>>, SongQuery>((ref, SongQuery q) async {
  return ref.read(searchRepositoryProvider).searchSongs(q.query, book: q.book, limit: 80);
});

/// Ranked hymn search across both books (used by global search).
final allSongsSearchProvider =
    FutureProvider.family<List<SearchHit<Song>>, String>((ref, String query) async {
  return ref.read(searchRepositoryProvider).searchAllSongs(query, limit: 40);
});

/// Ranked Bible verse search across Hindi + English.
final verseSearchProvider =
    FutureProvider.family<List<SearchHit<BibleVerse>>, String>((ref, String query) async {
  await ref.watch(bibleAssetReadyProvider.future);
  return ref.read(searchRepositoryProvider).searchVersesAllLanguages(query, limit: 60);
});
