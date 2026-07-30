import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../data/models/bible_verse.dart';
import '../../../data/repositories/planner_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/verse_background_settings.dart';
import '../../planner/domain/reading_plan.dart';
import '../../planner/presentation/planner_screen.dart';
import '../../weather/presentation/weather_card.dart';
import '../../../services/church_courtesy_service.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/editorial.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_heading.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  bool _checkedCourtesyPrompt = false;
  bool _syncNudgeDismissed = false;

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
    ref.listen<AsyncValue<BibleVerse?>>(dailyVerseProvider, (AsyncValue<BibleVerse?>? previous, AsyncValue<BibleVerse?> next) {
      final BibleVerse? verse = next.valueOrNull;
      if (verse != null) {
        ref.read(analyticsServiceProvider).logDailyVerseViewed(reference: verse.reference);
      }
    });
    final AsyncValue<BibleVerse?> dailyVerse = ref.watch(dailyVerseProvider);
    final VerseBackgroundSettings bgSettings = ref.watch(verseBackgroundControllerProvider);
    final AsyncValue<ProgressStats> stats = ref.watch(progressStatsProvider);
    final AsyncValue<ActivePlan?> activePlan = ref.watch(activePlanProvider);
    final AuthState authState = ref.watch(authControllerProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: <Widget>[
          // ── Hero verse plate ──────────────────────────────────────────
          dailyVerse.when(
            loading: () => const AspectRatio(
              aspectRatio: 21 / 12,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('बाइबल डेटा डाउनलोड हो रहा है…'),
                  ],
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (BibleVerse? verse) {
              if (verse == null) {
                return AspectRatio(
                  aspectRatio: 21 / 12,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.cloud_download_outlined, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            'आज का वचन लोड नहीं हो सका',
                            textAlign: TextAlign.center,
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go('/tab/bible'),
                            child: const Text('बाइबल टैब में पुनः प्रयास करें'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return VersePlate(
                eyebrow: 'आज का वचन',
                quote: verse.text,
                onTap: () => context.go('/tab/bible'),
                accentSrc: 'assets/3d-icons/dove_bird.png',
                backgroundSrc: bgSettings.resolve(DateTime.now()),
              );
            },
          ),
          dailyVerse.maybeWhen(
            data: (BibleVerse? verse) {
              if (verse == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        verse.reference,
                        style: text.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Share',
                      onPressed: () => Share.share('${verse.reference}\n${verse.text}'),
                      icon: const Icon(Icons.share_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Favorite',
                      onPressed: () async {
                        final ScaffoldMessengerState messenger =
                            ScaffoldMessenger.of(context);
                        await ref.read(favoritesRepositoryProvider).toggleFavorite(
                              itemType: 'verse',
                              itemRef: verse.id,
                            );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Daily verse favorite updated')),
                        );
                      },
                      icon: const Icon(Icons.favorite_border, size: 18),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Greeting + progress ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _greeting(),
                            style: text.headlineSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'गीत • वचन • धर्मशिक्षा • यात्रा',
                            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    activePlan.maybeWhen(
                      data: (ActivePlan? plan) {
                        if (plan == null) return const SizedBox.shrink();
                        final ReadingPlan rp = ReadingPlans.build(plan.planKey);
                        final int day = PlannerRepository.currentDayIndex(plan.startDate)
                            .clamp(0, rp.totalDays - 1);
                        final double progress =
                            rp.totalDays == 0 ? 0 : (day + 1) / rp.totalDays;
                        return Expanded(
                          flex: 2,
                          child: ThinProgressLine(label: 'पठन प्रगति', value: progress),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const WeatherCard(),
                const SizedBox(height: 14),
                const _TodayReadingCard(),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const SectionHeading(title: 'त्वरित पहुँच', subtitle: 'Quick access'),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: BentoCard(
                        claySrc: 'assets/3d-icons/musical_note.png',
                        title: 'गीत पुस्तक',
                        description: '353 हिंदी + 660 मुंडारी भजन',
                        footerLabel: 'Songs',
                        actionLabel: 'Open',
                        onTap: () => context.go('/tab/songs'),
                        accent: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BentoCard(
                        claySrc: 'assets/3d-icons/holy_bible.png',
                        title: 'धर्मशिक्षा',
                        description: 'Study pages & catechism',
                        footerLabel: 'Catechism',
                        actionLabel: 'Study',
                        onTap: () => context.push('/catechism'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: BentoCard(
                        claySrc: 'assets/3d-icons/journal_notebook.png',
                        title: 'पठन योजना',
                        description: 'Bible reading plans & streaks',
                        footerLabel: 'Planner',
                        actionLabel: 'Plan',
                        onTap: () => context.push('/planner'),
                        accent: true,
                        iconColor: colors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BentoCard(
                        claySrc: 'assets/3d-icons/christian_cross.png',
                        title: 'बाइबल प्रश्नोत्तरी',
                        description: 'Test and learn scripture',
                        footerLabel: 'Quiz',
                        actionLabel: 'Play',
                        onTap: () => context.push('/quiz'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const SectionHeading(title: 'यात्रा', subtitle: 'Journey snapshot'),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Progress unavailable right now.'),
              data: (ProgressStats value) => Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCard(
                      label: 'Streak',
                      value: '${value.currentStreak}',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: _StatCard(
                      label: 'Prayer Count',
                      value: '${value.totalPrayerCount}',
                      icon: Icons.self_improvement_outlined,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: _StatCard(
                      label: 'Prayer Days',
                      value: '${value.totalPrayerDays}',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
          stats.maybeWhen(
            data: (ProgressStats value) {
              final bool worthNudging = value.currentStreak >= 7 && !authState.isAuthenticated;
              if (!worthNudging || _syncNudgeDismissed) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _SyncNudgeCard(
                  streak: value.currentStreak,
                  onSignIn: () => context.push('/auth'),
                  onDismiss: () => setState(() => _syncNudgeDismissed = true),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 5) return 'शुभ रात्रि';
    if (hour < 12) return 'सुप्रभात';
    if (hour < 17) return 'नमस्ते';
    return 'शुभ संध्या';
  }
}

final FutureProvider<BibleVerse?> dailyVerseProvider =
    FutureProvider<BibleVerse?>((FutureProviderRef<BibleVerse?> ref) async {
  try {
    await ref.watch(bibleAssetReadyProvider.future);
  } catch (_) {
    return null;
  }
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
                const Icon(Icons.event_available_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Start a reading plan',
                          style: text.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
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
                  const Icon(Icons.event_available_outlined, size: 18),
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

/// A dismissible loss-aversion nudge: shown to anonymous/local-guest users
/// once their prayer streak is meaningful (7+ days) but not yet backed up
/// to the cloud. Dismissal is session-only (a plain [State] field, not
/// persisted) — it can reappear next app open rather than being silenced
/// forever after one tap, since the streak (and thus the risk of losing it)
/// keeps growing.
class _SyncNudgeCard extends StatelessWidget {
  const _SyncNudgeCard({
    required this.streak,
    required this.onSignIn,
    required this.onDismiss,
  });

  final int streak;
  final VoidCallback onSignIn;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GlassCard(
      child: Row(
        children: <Widget>[
          Icon(Icons.local_fire_department, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$streak-day streak — don\'t lose it',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign in to back up your streak, favorites, and reflections.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSignIn, child: const Text('Sign in')),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: 10),
          Text(value, style: text.headlineSmall?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 2),
          EyebrowLabel(label, fontSize: 9),
        ],
      ),
    );
  }
}
