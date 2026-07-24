import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../data/models/bible_verse.dart';
import '../../../data/models/catechism_chapter.dart';
import '../../../data/models/song.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<GlobalSearchResult> result = ref.watch(globalSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('Global Search')),
      body: AppBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: <Widget>[
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search Bible + Songs + Catechism',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                        ),
                ),
                onChanged: (String value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_query.trim().isEmpty)
                const Text('Type to search across songs, Bible verses, and catechism chapters.')
              else
                result.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (Object e, StackTrace _) => Text('Search failed: $e'),
                  data: (GlobalSearchResult data) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SectionHeader(title: 'Songs', count: data.songs.length),
                        const SizedBox(height: 8),
                        ...data.songs.map((Song song) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                onTap: () => context.push('/song/${song.id}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text('Geet ${song.id} • ${song.title}'),
                                    const SizedBox(height: 4),
                                    Text(song.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                        _SectionHeader(title: 'Bible', count: data.verses.length),
                        const SizedBox(height: 8),
                        ...data.verses.map((BibleVerse verse) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                onTap: () => context.go('/tab/bible'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(verse.reference),
                                    const SizedBox(height: 4),
                                    Text(verse.text, maxLines: 3, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                        _SectionHeader(title: 'Catechism', count: data.catechism.length),
                        const SizedBox(height: 8),
                        ...data.catechism.map((CatechismChapter chapter) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                onTap: () => context.push('/catechism/${chapter.id}'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(chapter.title),
                                    const SizedBox(height: 4),
                                    Text(
                                      chapter.content.replaceAll('\n', ' '),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 6),
        Text('($count)'),
      ],
    );
  }
}

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.songs,
    required this.verses,
    required this.catechism,
  });

  final List<Song> songs;
  final List<BibleVerse> verses;
  final List<CatechismChapter> catechism;
}

final globalSearchProvider = FutureProvider.family<GlobalSearchResult, String>(
  (ref, String query) async {
    final String q = query.trim();
    if (q.isEmpty) {
      return const GlobalSearchResult(songs: <Song>[], verses: <BibleVerse>[], catechism: <CatechismChapter>[]);
    }

    final songs = await ref.read(contentRepositoryProvider).getSongs(query: q);
    final verses = await ref.read(bibleRepositoryProvider).search(language: 'hi', query: q, limit: 20);
    final catechism = await ref.read(contentRepositoryProvider).getCatechismChapters();
    final String lower = q.toLowerCase();
    final catechismFiltered = catechism.where((CatechismChapter c) {
      return c.title.toLowerCase().contains(lower) || c.content.toLowerCase().contains(lower);
    }).take(20).toList(growable: false);

    return GlobalSearchResult(
      songs: songs.take(20).toList(growable: false),
      verses: verses,
      catechism: catechismFiltered,
    );
  },
);
