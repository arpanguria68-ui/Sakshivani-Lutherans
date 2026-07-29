import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/song.dart';
import '../../reader/controller/reader_settings_controller.dart';
import '../../reader/domain/reader_settings.dart';
import '../../reader/presentation/reader_body.dart';
import '../../reader/presentation/reader_settings_sheet.dart';
import '../../reader/presentation/tts_feedback.dart';
import '../../../services/tts_service.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';

class SongReaderScreen extends ConsumerStatefulWidget {
  const SongReaderScreen({
    super.key,
    required this.songId,
    this.book = 'sakshivani',
  });

  final int songId;
  final String book;

  @override
  ConsumerState<SongReaderScreen> createState() => _SongReaderScreenState();
}

class _SongReaderScreenState extends ConsumerState<SongReaderScreen> {
  bool _isPlaying = false;
  int? _activeLine;
  List<String> _lines = const <String>[];
  TtsService? _ttsService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the service reference while `ref` is still valid — reading a
    // provider from dispose() throws "Cannot use ref after disposed".
    _ttsService = ref.read(ttsServiceProvider);
  }

  @override
  void dispose() {
    _ttsService?.stop();
    super.dispose();
  }

  Future<void> _togglePlay(ReaderSettings settings) async {
    final tts = ref.read(ttsServiceProvider);
    if (_isPlaying) {
      await tts.pause();
      setState(() => _isPlaying = false);
      return;
    }
    if (_lines.isEmpty) return;
    setState(() => _isPlaying = true);
    await tts.speakLines(
      _lines,
      startIndex: _activeLine ?? 0,
      rate: settings.ttsRate,
      pitch: settings.ttsPitch,
      onLine: (int i) {
        if (mounted) setState(() => _activeLine = i);
      },
      onDone: () {
        if (mounted) setState(() {
          _isPlaying = false;
          _activeLine = null;
        });
      },
      onHindiUnavailable: () => warnHindiVoiceMissing(context),
    );
  }

  Future<void> _stop() async {
    await ref.read(ttsServiceProvider).stop();
    if (mounted) setState(() {
      _isPlaying = false;
      _activeLine = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final SongRef songRef = (book: widget.book, id: widget.songId);
    ref.listen<AsyncValue<Song?>>(songByIdProvider(songRef), (AsyncValue<Song?>? previous, AsyncValue<Song?> next) {
      final Song? loaded = next.valueOrNull;
      if (loaded != null) {
        ref.read(analyticsServiceProvider).logSongOpened(songId: loaded.id, book: widget.book);
      }
    });
    final AsyncValue<Song?> song = ref.watch(songByIdProvider(songRef));
    final ReaderSettings settings = ref.watch(readerSettingsControllerProvider);
    final ReaderPalette palette =
        ReaderPalette.resolve(settings, Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: settings.isPaperSurface ? palette.background : null,
      appBar: AppBar(
        backgroundColor: settings.isPaperSurface ? palette.background : null,
        foregroundColor: settings.isPaperSurface ? palette.text : null,
        title: Text('Geet ${widget.songId}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reading settings',
            icon: const Icon(Icons.text_fields),
            onPressed: () => showReaderSettingsSheet(context),
          ),
          IconButton(
            tooltip: 'Favorite',
            icon: const Icon(Icons.favorite_border),
            onPressed: () async {
              await ref
                  .read(favoritesRepositoryProvider)
                  .toggleFavorite(itemType: 'song', itemRef: '${widget.book}:${widget.songId}');
              ref.invalidate(favoriteSongsProvider);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Song favorite updated')));
            },
          ),
        ],
      ),
      body: song.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Could not load song: $e')),
        data: (Song? value) {
          if (value == null) {
            return const Center(child: Text('Song not found.'));
          }
          // Lyric lines are the shared unit for display, pagination, and TTS.
          _lines = value.lyrics.split('\n');

          final Widget header = _Header(song: value, palette: palette, paper: settings.isPaperSurface);
          final Widget body = ReaderBody(
            lines: _lines,
            settings: settings,
            palette: palette,
            activeLine: _activeLine,
          );

          final Widget content = Column(
            children: <Widget>[
              header,
              Expanded(child: body),
            ],
          );

          return settings.isPaperSurface
              ? content
              : AppBackdrop(child: content);
        },
      ),
      floatingActionButton: _PlaybackBar(
        isPlaying: _isPlaying,
        onPlayPause: () => _togglePlay(settings),
        onStop: _stop,
        paper: settings.isPaperSurface,
        palette: palette,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.song, required this.palette, required this.paper});

  final Song song;
  final ReaderPalette palette;
  final bool paper;

  @override
  Widget build(BuildContext context) {
    final Widget inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          song.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: paper ? palette.text : null,
              ),
        ),
        const SizedBox(height: 4),
        Text(song.category, style: TextStyle(color: palette.subtle)),
        if ((song.reference ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 2),
          Text(song.reference!, style: TextStyle(color: palette.subtle)),
        ],
      ],
    );

    if (paper) {
      return Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), child: inner);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GlassCard(child: inner),
    );
  }
}

class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({
    required this.isPlaying,
    required this.onPlayPause,
    required this.onStop,
    required this.paper,
    required this.palette,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final bool paper;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg = paper ? palette.background : colors.surfaceContainerHighest;
    final Color fg = paper ? palette.text : colors.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.subtle.withValues(alpha: 0.35)),
        boxShadow: paper
            ? null
            : <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onPlayPause,
            color: fg,
            icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 32),
            tooltip: isPlaying ? 'Pause' : 'Read aloud',
          ),
          IconButton(
            onPressed: onStop,
            color: fg,
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Stop',
          ),
        ],
      ),
    );
  }
}

typedef SongRef = ({String book, int id});

final songByIdProvider = FutureProvider.family<Song?, SongRef>((ref, SongRef r) async {
  return ref.read(contentRepositoryProvider).getSongById(r.id, book: r.book);
});

final favoriteSongsProvider =
    FutureProvider<List<String>>((FutureProviderRef<List<String>> ref) async {
  final items = await ref.read(favoritesRepositoryProvider).listFavoritesByType('song');
  return items.map((e) => e.itemRef).toList(growable: false);
});
