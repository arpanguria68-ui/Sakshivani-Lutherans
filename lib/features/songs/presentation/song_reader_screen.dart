import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../data/models/song.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';

class SongReaderScreen extends ConsumerStatefulWidget {
  const SongReaderScreen({super.key, required this.songId});

  final int songId;

  @override
  ConsumerState<SongReaderScreen> createState() => _SongReaderScreenState();
}

class _SongReaderScreenState extends ConsumerState<SongReaderScreen> {
  double _fontSize = AppConstants.songDefaultTextSize.toDouble();

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final double size = await ref.read(localStorageServiceProvider).getSongReaderFontSize();
    if (!mounted) {
      return;
    }
    setState(() {
      _fontSize = size;
    });
  }

  Future<void> _setFontSize(double value) async {
    final double clamped = value
        .clamp(
          AppConstants.songMinTextSize.toDouble(),
          AppConstants.songMaxTextSize.toDouble(),
        )
        .toDouble();
    setState(() {
      _fontSize = clamped;
    });
    await ref.read(localStorageServiceProvider).setSongReaderFontSize(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Song?> song = ref.watch(songByIdProvider(widget.songId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Geet ${widget.songId}'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () async {
              await ref
                  .read(favoritesRepositoryProvider)
                  .toggleFavorite(itemType: 'song', itemRef: widget.songId.toString());
              ref.invalidate(favoriteSongsProvider);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song favorite updated')));
            },
          ),
        ],
      ),
      body: AppBackdrop(
        child: song.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace _) => Center(child: Text('Could not load song: $e')),
          data: (Song? value) {
            if (value == null) {
              return const Center(child: Text('Song not found.'));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: <Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(value.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(value.category),
                      if ((value.reference ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(value.reference!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: SelectableText(
                    value.lyrics,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: _fontSize, height: 1.65),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              onPressed: () => _setFontSize(_fontSize - 2),
              icon: const Icon(Icons.text_decrease),
            ),
            Text(_fontSize.toInt().toString()),
            IconButton(
              onPressed: () => _setFontSize(_fontSize + 2),
              icon: const Icon(Icons.text_increase),
            ),
            IconButton(
              onPressed: () {
                context.push('/quiz');
              },
              icon: const Icon(Icons.quiz_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

final songByIdProvider = FutureProvider.family<Song?, int>((ref, int songId) async {
  return ref.read(contentRepositoryProvider).getSongById(songId);
});

final FutureProvider<List<String>> favoriteSongsProvider =
    FutureProvider<List<String>>((FutureProviderRef<List<String>> ref) async {
  final items = await ref.read(favoritesRepositoryProvider).listFavoritesByType('song');
  return items.map((e) => e.itemRef).toList(growable: false);
});
