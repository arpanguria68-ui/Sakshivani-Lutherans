import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../data/models/catechism_chapter.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';

class CatechismScreen extends ConsumerWidget {
  const CatechismScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CatechismChapter>> chapters = ref.watch(catechismChaptersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('धर्मशिक्षा')),
      body: AppBackdrop(
        child: SafeArea(
          child: chapters.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace _) => Center(child: Text('Could not load catechism: $e')),
            data: (List<CatechismChapter> items) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemBuilder: (BuildContext context, int index) {
                  final CatechismChapter chapter = items[index];
                  return GlassCard(
                    onTap: () => context.push('/catechism/${chapter.id}'),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(child: Text('${index + 1}')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            chapter.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: items.length,
              );
            },
          ),
        ),
      ),
    );
  }
}

final FutureProvider<List<CatechismChapter>> catechismChaptersProvider =
    FutureProvider<List<CatechismChapter>>((FutureProviderRef<List<CatechismChapter>> ref) async {
  return ref.read(contentRepositoryProvider).getCatechismChapters();
});
