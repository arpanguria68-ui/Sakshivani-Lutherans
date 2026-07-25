import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../data/models/bible_verse.dart';
import '../../reader/controller/reader_settings_controller.dart';
import '../../reader/domain/reader_settings.dart';
import '../../reader/presentation/reader_settings_sheet.dart';
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

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
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
    );
  }

  TextStyle _verseStyle(ReaderSettings s) => TextStyle(
        fontFamily: s.fontFamily,
        fontSize: s.fontSize,
        height: s.lineHeight,
        letterSpacing: s.letterSpacing,
        wordSpacing: s.wordSpacing,
      );

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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: <Widget>[
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
          if (_searchQuery.trim().isNotEmpty)
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Text('Could not load chapter: $e'),
              data: (List<BibleVerse> chapterVerses) {
                return Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: () => _readChapter(chapterVerses, settings),
                          icon: Icon(_isReading ? Icons.pause : Icons.volume_up),
                          label: Text(_isReading ? 'Pause' : 'Read chapter'),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Reading settings',
                          icon: const Icon(Icons.text_fields),
                          onPressed: () => showReaderSettingsSheet(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...chapterVerses.map((BibleVerse verse) {
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
                  }).toList(growable: false),
                  ],
                );
              },
            ),
          ],
        ],
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
