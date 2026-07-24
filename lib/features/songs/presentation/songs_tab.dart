import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../data/models/song.dart';
import 'song_reader_screen.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_heading.dart';

class SongsTab extends ConsumerStatefulWidget {
  const SongsTab({super.key});

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Song>> songs = ref.watch(songsProvider(_query));
    final AsyncValue<List<String>> favorites = ref.watch(favoriteSongsProvider);
    final Set<String> favoriteIds = favorites.value == null ? <String>{} : favorites.value!.toSet();

    return SafeArea(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: <Widget>[
                const SectionHeading(title: 'गीत पुस्तक', subtitle: 'Search by title, lyric, category, reference'),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (String value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: songs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Center(child: Text('Could not load songs: $e')),
              data: (List<Song> items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No songs found for this search.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final Song song = items[index];
                    return GlassCard(
                      onTap: () => context.push('/song/${song.id}'),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            child: Text('${song.id}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(song.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (favoriteIds.contains(song.id.toString()))
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.favorite,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final songsProvider = FutureProvider.family<List<Song>, String>((ref, String query) async {
  return ref.read(contentRepositoryProvider).getSongs(query: query);
});
