import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/prayer_log.dart';
import '../../../data/models/reflection_entry.dart';
import '../../home/presentation/home_tab.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_heading.dart';

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PrayerLog>> logs = ref.watch(prayerLogsProvider);
    final AsyncValue<List<ReflectionEntry>> reflections = ref.watch(reflectionsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: <Widget>[
          const SectionHeading(title: 'My Journey', subtitle: 'Prayer logs, reflections, and sync-aware progress'),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Prayer Log', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _openPrayerLogDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Today Entry'),
                ),
                const SizedBox(height: 10),
                logs.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object e, StackTrace _) => Text('Could not load prayer logs: $e'),
                  data: (List<PrayerLog> items) {
                    if (items.isEmpty) {
                      return const Text('No prayer logs yet.');
                    }
                    return Column(
                      children: items.take(10).map((PrayerLog log) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(log.dateIso),
                          subtitle: Text(log.notes.isEmpty ? 'No notes' : log.notes),
                          trailing: Text('x${log.count}'),
                        );
                      }).toList(growable: false),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Reflections', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openReflectionDialog(context, ref),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Add Reflection'),
                ),
                const SizedBox(height: 10),
                reflections.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object e, StackTrace _) => Text('Could not load reflections: $e'),
                  data: (List<ReflectionEntry> items) {
                    if (items.isEmpty) {
                      return const Text('No reflections yet.');
                    }
                    return Column(
                      children: items.take(15).map((ReflectionEntry item) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.verse),
                          subtitle: Text(item.text),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref.read(reflectionRepositoryProvider).deleteReflection(item.id);
                              ref.invalidate(reflectionsProvider);
                            },
                          ),
                        );
                      }).toList(growable: false),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrayerLogDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController countController = TextEditingController(text: '1');
    final TextEditingController notesController = TextEditingController();
    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Today Prayer Log'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prayer count'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
          ],
        );
      },
    );

    if (submit != true) {
      return;
    }

    final int count = int.tryParse(countController.text) ?? 1;
    await ref.read(progressRepositoryProvider).upsertPrayerLog(
          date: DateTime.now(),
          count: count,
          notes: notesController.text.trim(),
        );
    ref.invalidate(prayerLogsProvider);
    ref.invalidate(progressStatsProvider);
  }

  Future<void> _openReflectionDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController verseController = TextEditingController();
    final TextEditingController textController = TextEditingController();
    bool isPrivate = true;

    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('New Reflection'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: verseController,
                    decoration: const InputDecoration(labelText: 'Verse reference'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Reflection text'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: isPrivate,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Private reflection'),
                    onChanged: (bool value) => setState(() => isPrivate = value),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (submit != true) {
      return;
    }

    await ref.read(reflectionRepositoryProvider).addReflection(
          text: textController.text.trim(),
          verse: verseController.text.trim(),
          isPrivate: isPrivate,
        );
    ref.invalidate(reflectionsProvider);
  }
}

final FutureProvider<List<PrayerLog>> prayerLogsProvider =
    FutureProvider<List<PrayerLog>>((FutureProviderRef<List<PrayerLog>> ref) async {
  return ref.read(progressRepositoryProvider).getRecentPrayerLogs();
});

final FutureProvider<List<ReflectionEntry>> reflectionsProvider =
    FutureProvider<List<ReflectionEntry>>((FutureProviderRef<List<ReflectionEntry>> ref) async {
  return ref.read(reflectionRepositoryProvider).getReflections();
});
