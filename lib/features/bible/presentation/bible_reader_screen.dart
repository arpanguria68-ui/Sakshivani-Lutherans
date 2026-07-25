import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/bible/bible_books.dart';
import '../../../data/models/bible_verse.dart';
import '../../reader/controller/reader_settings_controller.dart';
import '../../reader/domain/reader_settings.dart';
import '../../reader/presentation/reader_body.dart';
import '../../reader/presentation/reader_settings_sheet.dart';
import 'bible_tab.dart' show bibleVersesProvider, BibleLocation;

/// Full-screen chapter reader with e-ink/scroll modes, TTS, and chapter
/// navigation. Persists last-read position and pushes to reading history.
class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({
    super.key,
    required this.language,
    required this.bookIndex,
    required this.chapterIndex,
  });

  final String language;
  final int bookIndex;
  final int chapterIndex;

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  late String _language = widget.language;
  late int _book = widget.bookIndex;
  late int _chapter = widget.chapterIndex;
  bool _isPlaying = false;
  int? _activeLine;
  List<String> _lines = const <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordPosition());
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  Future<void> _recordPosition() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setBibleLastRead(_language, _book, _chapter);
    await storage.pushBibleHistory(_language, _book, _chapter);
  }

  Future<void> _stopTts() async {
    await ref.read(ttsServiceProvider).stop();
    if (mounted) setState(() {
      _isPlaying = false;
      _activeLine = null;
    });
  }

  Future<void> _goChapter(int book, int chapter) async {
    await _stopTts();
    setState(() {
      _book = book;
      _chapter = chapter;
    });
    _recordPosition();
  }

  Future<void> _prev() async {
    if (_chapter > 0) {
      _goChapter(_book, _chapter - 1);
    } else if (_book > 0) {
      final int prevBook = _book - 1;
      _goChapter(prevBook, BibleBooks.chapterCounts[prevBook] - 1);
    }
  }

  Future<void> _next() async {
    final int count = BibleBooks.chapterCounts[_book];
    if (_chapter + 1 < count) {
      _goChapter(_book, _chapter + 1);
    } else if (_book < 65) {
      _goChapter(_book + 1, 0);
    }
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReaderSettings settings = ref.watch(readerSettingsControllerProvider);
    final ReaderPalette palette =
        ReaderPalette.resolve(settings, Theme.of(context).brightness);
    final bool paper = settings.isPaperSurface;
    final AsyncValue<List<BibleVerse>> verses = ref.watch(
      bibleVersesProvider(BibleLocation(
          language: _language, bookIndex: _book, chapterIndex: _chapter)),
    );
    final String title = '${BibleBooks.name(_book, _language)} ${_chapter + 1}';

    return Scaffold(
      backgroundColor: paper ? palette.background : null,
      appBar: AppBar(
        backgroundColor: paper ? palette.background : null,
        foregroundColor: paper ? palette.text : null,
        title: Text(title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reading settings',
            icon: const Icon(Icons.text_fields),
            onPressed: () => showReaderSettingsSheet(context),
          ),
          IconButton(
            tooltip: _isPlaying ? 'Pause' : 'Read aloud',
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
            onPressed: () => _togglePlay(settings),
          ),
        ],
      ),
      body: verses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Could not load chapter: $e')),
        data: (List<BibleVerse> chapterVerses) {
          _lines = chapterVerses
              .map((BibleVerse v) => '${v.verse}  ${v.text}')
              .toList(growable: false);
          return ReaderBody(
            lines: _lines,
            settings: settings,
            palette: palette,
            activeLine: _activeLine,
          );
        },
      ),
      bottomNavigationBar: _ChapterNavBar(
        paper: paper,
        palette: palette,
        onPrev: _prev,
        onNext: _next,
        title: title,
      ),
    );
  }
}

class _ChapterNavBar extends StatelessWidget {
  const _ChapterNavBar({
    required this.paper,
    required this.palette,
    required this.onPrev,
    required this.onNext,
    required this.title,
  });

  final bool paper;
  final ReaderPalette palette;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg = paper ? palette.background : colors.surface;
    final Color fg = paper ? palette.text : colors.onSurface;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: palette.subtle.withValues(alpha: 0.3))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: <Widget>[
            TextButton.icon(
              onPressed: onPrev,
              icon: Icon(Icons.chevron_left, color: fg),
              label: Text('Prev', style: TextStyle(color: fg)),
            ),
            const Spacer(),
            Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              onPressed: onNext,
              icon: Icon(Icons.chevron_right, color: fg),
              label: Text('Next', style: TextStyle(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}
