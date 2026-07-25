import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../data/models/song.dart';
import '../../../data/search/search_engine.dart';
import '../../search/providers/search_providers.dart';
import 'song_reader_screen.dart' show favoriteSongsProvider;
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/highlighted_text.dart';
import '../../../shared/widgets/section_heading.dart';

class SongsTab extends ConsumerStatefulWidget {
  const SongsTab({super.key});

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _book = AppConstants.bookSakshivani;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchRepositoryProvider).warmUp(languages: const <String>[]);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clear() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  void _setBook(String book) {
    setState(() => _book = book);
  }

  @override
  Widget build(BuildContext context) {
    final bool searching = _query.isNotEmpty;
    final AsyncValue<List<String>> favorites = ref.watch(favoriteSongsProvider);
    final Set<String> favoriteIds =
        favorites.value == null ? <String>{} : favorites.value!.toSet();

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: <Widget>[
                const SectionHeading(
                  title: 'गीत पुस्तक',
                  subtitle: 'Smart search — title, lyric, or romanised Hindi',
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: AppConstants.bookSakshivani,
                      label: Text(AppConstants.bookSakshivaniLabel),
                    ),
                    ButtonSegment<String>(
                      value: AppConstants.bookDurang,
                      label: Text(AppConstants.bookDurangLabel),
                    ),
                  ],
                  selected: <String>{_book},
                  onSelectionChanged: (Set<String> v) => _setBook(v.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search songs… (e.g. yeeshu, prabhu, आराधना)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(onPressed: _clear, icon: const Icon(Icons.close)),
                  ),
                  onChanged: _onQueryChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: searching
                ? _buildSearchResults(favoriteIds)
                : _buildBrowseList(favoriteIds),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseList(Set<String> favoriteIds) {
    final AsyncValue<List<Song>> songs = ref.watch(songsProvider((book: _book, query: '')));
    return songs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace _) => Center(child: Text('Could not load songs: $e')),
      data: (List<Song> items) {
        if (items.isEmpty) {
          return const Center(child: Text('No songs available.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) {
            final Song song = items[index];
            return _SongCard(
              song: song,
              isFavorite: favoriteIds.contains('${song.book}:${song.id}') ||
                  (song.book == AppConstants.bookSakshivani &&
                      favoriteIds.contains(song.id.toString())),
              matchedTerms: const <String>{},
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(Set<String> favoriteIds) {
    final AsyncValue<List<SearchHit<Song>>> results =
        ref.watch(songSearchProvider((book: _book, query: _query)));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace _) => Center(child: Text('Search failed: $e')),
      data: (List<SearchHit<Song>> hits) {
        if (hits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No matches for “$_query”.\nTry a different word or spelling.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          itemCount: hits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) {
            final SearchHit<Song> hit = hits[index];
            return _SongCard(
              song: hit.ref,
              isFavorite: favoriteIds.contains('${hit.ref.book}:${hit.ref.id}') ||
                  (hit.ref.book == AppConstants.bookSakshivani &&
                      favoriteIds.contains(hit.ref.id.toString())),
              matchedTerms: hit.matchedTerms,
            );
          },
        );
      },
    );
  }
}

class _SongCard extends StatelessWidget {
  const _SongCard({
    required this.song,
    required this.isFavorite,
    required this.matchedTerms,
  });

  final Song song;
  final bool isFavorite;
  final Set<String> matchedTerms;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/song/${song.book}/${song.id}'),
      child: Row(
        children: <Widget>[
          CircleAvatar(child: Text('${song.id}')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                HighlightedText(
                  text: song.title,
                  terms: matchedTerms,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isFavorite)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.favorite, size: 18, color: Theme.of(context).colorScheme.primary),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

final songsProvider = FutureProvider.family<List<Song>, SongQuery>((ref, SongQuery q) async {
  return ref.read(contentRepositoryProvider).getSongs(query: q.query, book: q.book);
});
