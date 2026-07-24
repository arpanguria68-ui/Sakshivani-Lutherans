/// Riverpod providers backing the ranked search bars (songs + Bible).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/bible_verse.dart';
import '../../../data/models/song.dart';
import '../../../data/search/search_engine.dart';

/// Ranked hymn search. Empty query yields no hits (browse list handled by the
/// tab itself). Debouncing is done at the widget layer.
final songSearchProvider =
    FutureProvider.family<List<SearchHit<Song>>, String>((ref, String query) async {
  return ref.read(searchRepositoryProvider).searchSongs(query, limit: 80);
});

/// Ranked Bible verse search across Hindi + English.
final verseSearchProvider =
    FutureProvider.family<List<SearchHit<BibleVerse>>, String>((ref, String query) async {
  return ref.read(searchRepositoryProvider).searchVersesAllLanguages(query, limit: 60);
});
