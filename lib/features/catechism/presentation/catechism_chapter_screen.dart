import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/clean_markdown.dart';
import '../../../data/models/catechism_chapter.dart';
import '../../../shared/widgets/app_backdrop.dart';
import 'catechism_screen.dart';

class CatechismChapterScreen extends ConsumerWidget {
  const CatechismChapterScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CatechismChapter>> chapters = ref.watch(catechismChaptersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('धर्मशिक्षा अध्ययन')),
      body: AppBackdrop(
        child: SafeArea(
          child: chapters.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace _) => Center(child: Text('Could not load chapter: $e')),
            data: (List<CatechismChapter> items) {
              final int index = items.indexWhere((CatechismChapter item) => item.id == chapterId);
              if (index == -1) {
                return const Center(child: Text('Chapter not found.'));
              }
              final CatechismChapter chapter = items[index];

              return Column(
                children: <Widget>[
                  Expanded(
                    child: Markdown(
                      data: cleanCatechismMarkdown(chapter.content),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      selectable: true,
                    ),
                  ),
                  _FooterNav(
                    index: index,
                    total: items.length,
                    onPrev: index == 0 ? null : () => context.go('/catechism/${items[index - 1].id}'),
                    onNext: index == items.length - 1
                        ? null
                        : () => context.go('/catechism/${items[index + 1].id}'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FooterNav extends StatelessWidget {
  const _FooterNav({
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int index;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color footerSurface = Color.fromRGBO(
      colors.surface.red,
      colors.surface.green,
      colors.surface.blue,
      0.88,
    );
    final Color footerBorder = Color.fromRGBO(
      colors.outlineVariant.red,
      colors.outlineVariant.green,
      colors.outlineVariant.blue,
      0.5,
    );
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
          Text('${index + 1} / $total'),
          const Spacer(),
          TextButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward), label: const Text('Next')),
        ],
      ),
    );
  }
}
