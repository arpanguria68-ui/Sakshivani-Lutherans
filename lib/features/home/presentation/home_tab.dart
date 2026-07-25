import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../data/models/bible_verse.dart';
import '../../../data/repositories/planner_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../planner/domain/reading_plan.dart';
import '../../planner/presentation/planner_screen.dart';
import '../../weather/presentation/weather_card.dart';
import '../../../services/church_courtesy_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_heading.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  bool _checkedCourtesyPrompt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedCourtesyPrompt) {
      return;
    }
    _checkedCourtesyPrompt = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCourtesyPrompt();
    });
  }

  Future<void> _checkCourtesyPrompt() async {
    final ChurchCourtesyService service = ref.read(churchCourtesyServiceProvider);
    final bool shouldPrompt = await service.shouldPromptNow();
    if (!mounted || !shouldPrompt) {
      return;
    }

    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Worship Courtesy'),
          content: const Text(
            'Service may be in progress. Would you like Sakshi Vani to lower media volume?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop('snooze'),
              child: const Text('Not now'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop('settings'),
              child: const Text('Open DND settings'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('lower'),
              child: const Text('Lower volume'),
            ),
          ],
        );
      },
    );

    switch (action) {
      case 'lower':
        await service.lowerVolumeForService();
        await service.snoozePrompt(const Duration(hours: 2));
        break;
      case 'settings':
        await service.openDoNotDisturbSettings();
        await service.snoozePrompt(const Duration(hours: 2));
        break;
      case 'snooze':
        await service.snoozePrompt(const Duration(hours: 2));
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BibleVerse?> dailyVerse = ref.watch(dailyVerseProvider);
    final AsyncValue<ProgressStats> stats = ref.watch(progressStatsProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: <Widget>[
          Text('साक्षी वाणी', style: text.displaySmall),
          const SizedBox(height: 4),
          Text('गीत • वचन • धर्मशिक्षा • यात्रा', style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          const WeatherCard(),
          const SizedBox(height: 14),
          GlassCard(
            onTap: () => context.go('/tab/bible'),
            child: dailyVerse.when(
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const Text('आज का वचन उपलब्ध नहीं है।'),
              data: (BibleVerse? verse) {
                if (verse == null) {
                  return const Text('आज का वचन उपलब्ध नहीं है।');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('आज का वचन', style: text.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      '"${verse.text}"',
                      style: text.bodyLarge?.copyWith(fontSize: 20, height: 1.6),
                    ),
                    const SizedBox(height: 8),
                    Text(verse.reference, style: text.bodyMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => Share.share('${verse.reference}\n${verse.text}'),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(favoritesRepositoryProvider).toggleFavorite(
                                  itemType: 'verse',
                                  itemRef: verse.id,
                                );
                            if (!mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Daily verse favorite updated')),
                            );
                          },
                          icon: const Icon(Icons.favorite_border),
                          label: const Text('Favorite'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const _TodayReadingCard(),
          const SizedBox(height: 18),
          const SectionHeading(title: 'Quick Access'),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.library_music,
                  title: 'Songs',
                  subtitle: '353+ hymns',
                  onTap: () => context.go('/tab/songs'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.menu_book,
                  title: 'Catechism',
                  subtitle: 'Study pages',
                  onTap: () => context.push('/catechism'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.quiz,
                  title: 'Bible Quiz',
                  subtitle: 'Test and learn',
                  onTap: () => context.push('/quiz'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.event_available,
                  title: 'Planner',
                  subtitle: 'Reading plans',
                  onTap: () => context.push('/planner'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeading(title: 'Journey Snapshot'),
          const SizedBox(height: 12),
          stats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Progress unavailable right now.'),
            data: (ProgressStats value) => Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    label: 'Streak',
                    value: '${value.currentStreak}',
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Prayer Count',
                    value: '${value.totalPrayerCount}',
                    icon: Icons.self_improvement,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Prayer Days',
                    value: '${value.totalPrayerDays}',
                    icon: Icons.calendar_month,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final FutureProvider<BibleVerse?> dailyVerseProvider =
    FutureProvider<BibleVerse?>((FutureProviderRef<BibleVerse?> ref) async {
  return ref.read(bibleRepositoryProvider).getDailyVerse(language: 'hi');
});

final FutureProvider<ProgressStats> progressStatsProvider =
    FutureProvider<ProgressStats>((FutureProviderRef<ProgressStats> ref) async {
  return ref.read(progressRepositoryProvider).getProgressStats();
});

class _TodayReadingCard extends ConsumerWidget {
  const _TodayReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ActivePlan?> active = ref.watch(activePlanProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return active.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ActivePlan? plan) {
        if (plan == null) {
          return GlassCard(
            onTap: () => context.push('/planner'),
            child: Row(
              children: <Widget>[
                const Icon(Icons.event_available),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Start a reading plan', style: text.titleMedium),
                      Text('Daily Bible readings with progress', style: text.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          );
        }
        final ReadingPlan rp = ReadingPlans.build(plan.planKey);
        final int day = PlannerRepository.currentDayIndex(plan.startDate)
            .clamp(0, rp.totalDays - 1);
        return GlassCard(
          onTap: () => context.push('/planner'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.event_available, size: 18),
                  const SizedBox(width: 6),
                  Text("Today's reading · Day ${day + 1}", style: text.titleMedium),
                ],
              ),
              const SizedBox(height: 6),
              Text(rp.days[day].label('hi'),
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(rp.title, style: text.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, style: text.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(value, style: text.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}
