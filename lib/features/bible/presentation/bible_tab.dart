import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../data/bible/bible_books.dart';
import '../../../data/models/bible_verse.dart';
import '../../reader/controller/reader_settings_controller.dart';
import '../../reader/domain/reader_settings.dart';
import '../../reader/presentation/reader_settings_sheet.dart';
import '../../reader/presentation/tts_feedback.dart';
import '../../../services/tts_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_heading.dart';

class BibleTab extends ConsumerStatefulWidget {
  const BibleTab({super.key});

  @override
  ConsumerState<BibleTab> createState() => _BibleTabState();
}

class _BibleTabState extends ConsumerState<BibleTab> {
  String _language = 'hi';
  int _bookIndex = 0;
  int _chapterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isReading = false;
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _readChapter(List<BibleVerse> verses, ReaderSettings settings) async {
    final tts = ref.read(ttsServiceProvider);
    if (_isReading) {
      await tts.pause();
      if (mounted) setState(() => _isReading = false);
      return;
    }
    if (verses.isEmpty) return;
    setState(() => _isReading = true);
    await tts.speakLines(
      verses.map((BibleVerse v) => v.text).toList(growable: false),
      rate: settings.ttsRate,
      pitch: settings.ttsPitch,
      onLine: (_) {},
      onDone: () {
        if (mounted) setState(() => _isReading = false);
      },
      onHindiUnavailable: () => warnHindiVoiceMissing(context),
    );
  }

  TextStyle _verseStyle(ReaderSettings s) => TextStyle(
        fontFamily: s.fontFamily,
        fontSize: s.fontSize,
        height: s.lineHeight,
        letterSpacing: s.letterSpacing,
        wordSpacing: s.wordSpacing,
      );

  void _openReader(int book, int chapter, {String? language}) {
    context
        .push('/bible/read/${language ?? _language}/$book/$chapter')
        .then((_) {
      if (!mounted) return;
      ref.invalidate(bibleLastReadProvider);
      ref.invalidate(bibleHistoryProvider);
    });
  }

  /// "Continue reading" card + a horizontal strip of recent chapters.
  Widget _continueAndRecent() {
    final AsyncValue<Map<String, dynamic>?> last = ref.watch(bibleLastReadProvider);
    final AsyncValue<List<Map<String, dynamic>>> history = ref.watch(bibleHistoryProvider);

    final Map<String, dynamic>? lastRead = last.value;
    final List<Map<String, dynamic>> recents = history.value ?? const <Map<String, dynamic>>[];
    if (lastRead == null && recents.isEmpty) {
      return const SizedBox.shrink();
    }

    String labelFor(Map<String, dynamic> e) {
      final String lang = e['language'] as String? ?? 'hi';
      final int b = (e['bookIndex'] as num?)?.toInt() ?? 0;
      final int c = (e['chapterIndex'] as num?)?.toInt() ?? 0;
      return '${BibleBooks.name(b, lang)} ${c + 1}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (lastRead != null) ...<Widget>[
          GlassCard(
            onTap: () => _openReader(
              (lastRead['bookIndex'] as num?)?.toInt() ?? 0,
              (lastRead['chapterIndex'] as num?)?.toInt() ?? 0,
              language: lastRead['language'] as String? ?? 'hi',
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.play_circle_fill),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Continue reading', style: Theme.of(context).textTheme.bodySmall),
                      Text(labelFor(lastRead),
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (recents.isNotEmpty) ...<Widget>[
          Text('Recent', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int i) {
                final Map<String, dynamic> e = recents[i];
                return ActionChip(
                  label: Text(labelFor(e)),
                  onPressed: () => _openReader(
                    (e['bookIndex'] as num?)?.toInt() ?? 0,
                    (e['chapterIndex'] as num?)?.toInt() ?? 0,
                    language: e['language'] as String? ?? 'hi',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _nextChapter() async {
    final List<String> names = await ref.read(bibleBooksProvider(_language).future);
    if (names.isEmpty) {
      return;
    }

    final int chapters = await ref
        .read(bibleRepositoryProvider)
        .getChapterCount(language: _language, bookIndex: _bookIndex);
    if (_chapterIndex + 1 < chapters) {
      setState(() {
        _chapterIndex += 1;
      });
      return;
    }
    if (_bookIndex < names.length - 1) {
      setState(() {
        _bookIndex += 1;
        _chapterIndex = 0;
      });
    }
  }

  Future<void> _prevChapter() async {
    if (_chapterIndex > 0) {
      setState(() {
        _chapterIndex -= 1;
      });
      return;
    }
    if (_bookIndex > 0) {
      final int prevBook = _bookIndex - 1;
      final int chapterCount = await ref
          .read(bibleRepositoryProvider)
          .getChapterCount(language: _language, bookIndex: prevBook);
      setState(() {
        _bookIndex = prevBook;
        _chapterIndex = chapterCount - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<String>> books = ref.watch(bibleBooksProvider(_language));
    final AsyncValue<List<BibleVerse>> verses = ref.watch(
      bibleVersesProvider(BibleLocation(language: _language, bookIndex: _bookIndex, chapterIndex: _chapterIndex)),
    );
    final AsyncValue<List<BibleVerse>> searchResults = ref.watch(
      bibleSearchProvider(BibleSearchRequest(language: _language, query: _searchQuery)),
    );
    final ReaderSettings settings = ref.watch(readerSettingsControllerProvider);
    final TextStyle verseStyle = _verseStyle(settings);
    final bool searching = _searchQuery.trim().isNotEmpty;

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
          const SectionHeading(title: 'Bible Reader', subtitle: 'Offline Hindi + English with share support'),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'hi', label: Text('हिंदी')),
                    ButtonSegment<String>(value: 'en', label: Text('English')),
                  ],
                  selected: <String>{_language},
                  onSelectionChanged: (Set<String> value) {
                    final String next = value.first;
                    setState(() {
                      _language = next;
                      _bookIndex = 0;
                      _chapterIndex = 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _language == 'hi' ? 'वचन खोजें...' : 'Search verses...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (String value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 10),
          if (searching)
            searchResults.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, StackTrace _) => Text('Search failed: $e'),
              data: (List<BibleVerse> result) {
                if (result.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No matching verses found.'),
                  );
                }
                return Column(
                  children: result.take(40).map((BibleVerse verse) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(verse.reference, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            SelectableText(verse.text, style: verseStyle),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: '${verse.reference}\n${verse.text}'),
                                    );
                                    if (!mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Verse copied')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy'),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Share.share('${verse.reference}\n${verse.text}');
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            )
          else ...<Widget>[
            _continueAndRecent(),
            books.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Text('Could not load books: $e'),
              data: (List<String> names) {
                final List<DropdownMenuItem<int>> items = List<DropdownMenuItem<int>>.generate(
                  names.length,
                  (int idx) => DropdownMenuItem<int>(value: idx, child: Text(names[idx])),
                );
                return Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey<String>('book-$_language-$_bookIndex'),
                        initialValue: _bookIndex,
                        items: items,
                        decoration: const InputDecoration(labelText: 'Book'),
                        onChanged: (int? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _bookIndex = value;
                            _chapterIndex = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey<String>('$_language-$_bookIndex-$_chapterIndex'),
                        initialValue: '${_chapterIndex + 1}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Chapter'),
                        onFieldSubmitted: (String value) async {
                          final int? parsed = int.tryParse(value);
                          if (parsed == null || parsed < 1) {
                            return;
                          }
                          final int count = await ref
                              .read(bibleRepositoryProvider)
                              .getChapterCount(language: _language, bookIndex: _bookIndex);
                          setState(() {
                            _chapterIndex = (parsed - 1).clamp(0, count - 1).toInt();
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _prevChapter,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _nextChapter,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            verses.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, StackTrace _) => Text('Could not load chapter: $e'),
              data: (List<BibleVerse> chapterVerses) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () => _openReader(_bookIndex, _chapterIndex),
                      icon: const Icon(Icons.auto_stories),
                      label: const Text('Open reader'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _readChapter(chapterVerses, settings),
                      icon: Icon(_isReading ? Icons.pause : Icons.volume_up),
                      label: Text(_isReading ? 'Pause' : 'Read aloud'),
                    ),
                    IconButton(
                      tooltip: 'Reading settings',
                      icon: const Icon(Icons.text_fields),
                      onPressed: () => showReaderSettingsSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
              ]),
            ),
          ),
          // Verse cards get their own lazily-built sliver — long chapters
          // (Psalm 119 = 176 verses) used to unroll every GlassCard up front
          // as part of one big Column, causing jank on open/scroll.
          if (!searching)
            verses.maybeWhen(
              data: (List<BibleVerse> chapterVerses) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int i) => _verseCard(chapterVerses[i], verseStyle),
                    childCount: chapterVerses.length,
                  ),
                ),
              ),
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _verseCard(BibleVerse verse, TextStyle verseStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${verse.verse}', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SelectableText(verse.text, style: verseStyle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: <Widget>[
                ActionChip(
                  label: const Text('Copy'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: '${verse.reference}\n${verse.text}'),
                    );
                  },
                ),
                ActionChip(
                  label: const Text('Share'),
                  onPressed: () => Share.share('${verse.reference}\n${verse.text}'),
                ),
                ActionChip(
                  label: const Text('Favorite'),
                  onPressed: () async {
                    await ref.read(favoritesRepositoryProvider).toggleFavorite(
                          itemType: 'verse',
                          itemRef: verse.id,
                        );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BibleLocation {
  const BibleLocation({
    required this.language,
    required this.bookIndex,
    required this.chapterIndex,
  });

  final String language;
  final int bookIndex;
  final int chapterIndex;

  @override
  bool operator ==(Object other) {
    return other is BibleLocation &&
        other.language == language &&
        other.bookIndex == bookIndex &&
        other.chapterIndex == chapterIndex;
  }

  @override
  int get hashCode => Object.hash(language, bookIndex, chapterIndex);
}

class BibleSearchRequest {
  const BibleSearchRequest({required this.language, required this.query});

  final String language;
  final String query;

  @override
  bool operator ==(Object other) {
    return other is BibleSearchRequest && other.language == language && other.query == query;
  }

  @override
  int get hashCode => Object.hash(language, query);
}

final bibleBooksProvider = FutureProvider.family<List<String>, String>((ref, String language) async {
  return ref.read(bibleRepositoryProvider).getBooks(language);
});

/// Last-read {language, bookIndex, chapterIndex}, or null.
final bibleLastReadProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.read(localStorageServiceProvider).getBibleLastRead();
});

/// Recent chapters (most-recent-first).
final bibleHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(localStorageServiceProvider).getBibleHistory();
});

final bibleVersesProvider = FutureProvider.family<List<BibleVerse>, BibleLocation>(
  (ref, BibleLocation location) async {
    return ref.read(bibleRepositoryProvider).getVerses(
          language: location.language,
          bookIndex: location.bookIndex,
          chapterIndex: location.chapterIndex,
        );
  },
);

final bibleSearchProvider = FutureProvider.family<List<BibleVerse>, BibleSearchRequest>(
  (ref, BibleSearchRequest query) async {
    final hits = await ref
        .read(searchRepositoryProvider)
        .searchVerses(query.language, query.query, limit: 80);
    return hits.map((h) => h.ref).toList(growable: false);
  },
);
