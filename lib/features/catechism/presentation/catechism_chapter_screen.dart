import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/clean_markdown.dart';
import '../../../data/models/catechism_chapter.dart';
import '../../reader/controller/reader_settings_controller.dart';
import '../../reader/domain/reader_settings.dart';
import '../../reader/presentation/reader_settings_sheet.dart';
import '../../../shared/widgets/app_backdrop.dart';
import 'catechism_screen.dart';

class CatechismChapterScreen extends ConsumerStatefulWidget {
  const CatechismChapterScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<CatechismChapterScreen> createState() => _CatechismChapterScreenState();
}

class _CatechismChapterScreenState extends ConsumerState<CatechismChapterScreen> {
  bool _isPlaying = false;

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  /// Strip markdown markup to plain lines for read-aloud.
  List<String> _plainLines(String markdown) {
    return markdown
        .split('\n')
        .map((String l) => l
            .replaceAll(RegExp(r'[#>*_`~]'), '')
            .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
            .replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1')
            .trim())
        .where((String l) => l.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _togglePlay(String markdown, ReaderSettings settings) async {
    final tts = ref.read(ttsServiceProvider);
    if (_isPlaying) {
      await tts.pause();
      setState(() => _isPlaying = false);
      return;
    }
    final List<String> lines = _plainLines(markdown);
    if (lines.isEmpty) return;
    setState(() => _isPlaying = true);
    await tts.speakLines(
      lines,
      rate: settings.ttsRate,
      pitch: settings.ttsPitch,
      onLine: (_) {},
      onDone: () {
        if (mounted) setState(() => _isPlaying = false);
      },
    );
  }

  MarkdownStyleSheet _markdownStyle(ReaderSettings s, ReaderPalette palette) {
    final TextStyle body = TextStyle(
      fontFamily: s.fontFamily,
      fontSize: s.fontSize,
      height: s.lineHeight,
      letterSpacing: s.letterSpacing,
      wordSpacing: s.wordSpacing,
      color: palette.text,
    );
    return MarkdownStyleSheet(
      p: body,
      listBullet: body,
      h1: body.copyWith(fontSize: s.fontSize * 1.6, fontWeight: FontWeight.w700),
      h2: body.copyWith(fontSize: s.fontSize * 1.4, fontWeight: FontWeight.w700),
      h3: body.copyWith(fontSize: s.fontSize * 1.2, fontWeight: FontWeight.w600),
      strong: body.copyWith(fontWeight: FontWeight.w700),
      em: body.copyWith(fontStyle: FontStyle.italic),
      blockquote: body.copyWith(color: palette.subtle),
      textAlign: switch (s.align) {
        ReaderAlign.center => WrapAlignment.center,
        ReaderAlign.justify => WrapAlignment.spaceBetween,
        ReaderAlign.start => WrapAlignment.start,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<CatechismChapter>> chapters =
        ref.watch(catechismChaptersProvider);
    final ReaderSettings settings = ref.watch(readerSettingsControllerProvider);
    final ReaderPalette palette =
        ReaderPalette.resolve(settings, Theme.of(context).brightness);
    final bool paper = settings.isPaperSurface;

    final Widget content = SafeArea(
      child: chapters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('Could not load chapter: $e')),
        data: (List<CatechismChapter> items) {
          final int index = items.indexWhere((CatechismChapter item) => item.id == widget.chapterId);
          if (index == -1) {
            return const Center(child: Text('Chapter not found.'));
          }
          final CatechismChapter chapter = items[index];
          final String md = cleanCatechismMarkdown(chapter.content);

          return Column(
            children: <Widget>[
              Expanded(
                child: Markdown(
                  data: md,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  selectable: true,
                  styleSheet: _markdownStyle(settings, palette),
                ),
              ),
              _FooterNav(
                index: index,
                total: items.length,
                paper: paper,
                palette: palette,
                onPrev: index == 0 ? null : () => context.go('/catechism/${items[index - 1].id}'),
                onNext: index == items.length - 1
                    ? null
                    : () => context.go('/catechism/${items[index + 1].id}'),
              ),
            ],
          );
        },
      ),
    );

    final String rawForTts = chapters.value == null
        ? ''
        : () {
            final int i = chapters.value!.indexWhere((c) => c.id == widget.chapterId);
            return i == -1 ? '' : cleanCatechismMarkdown(chapters.value![i].content);
          }();

    return Scaffold(
      backgroundColor: paper ? palette.background : null,
      appBar: AppBar(
        backgroundColor: paper ? palette.background : null,
        foregroundColor: paper ? palette.text : null,
        title: const Text('धर्मशिक्षा अध्ययन'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reading settings',
            icon: const Icon(Icons.text_fields),
            onPressed: () => showReaderSettingsSheet(context),
          ),
          IconButton(
            tooltip: _isPlaying ? 'Pause' : 'Read aloud',
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
            onPressed: rawForTts.isEmpty ? null : () => _togglePlay(rawForTts, settings),
          ),
        ],
      ),
      body: paper ? content : AppBackdrop(child: content),
    );
  }
}

class _FooterNav extends StatelessWidget {
  const _FooterNav({
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.paper,
    required this.palette,
  });

  final int index;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool paper;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color footerSurface = paper
        ? palette.background
        : colors.surface.withValues(alpha: 0.88);
    final Color footerBorder = (paper ? palette.subtle : colors.outlineVariant)
        .withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: footerSurface,
        border: Border(top: BorderSide(color: footerBorder)),
      ),
      child: Row(
        children: <Widget>[
          TextButton.icon(onPressed: onPrev, icon: const Icon(Icons.arrow_back), label: const Text('Previous')),
          const Spacer(),
          Text('${index + 1} / $total', style: TextStyle(color: paper ? palette.text : null)),
          const Spacer(),
          TextButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward), label: const Text('Next')),
        ],
      ),
    );
  }
}
