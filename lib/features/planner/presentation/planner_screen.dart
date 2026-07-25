import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../data/repositories/planner_repository.dart';
import '../../../shared/widgets/app_backdrop.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_heading.dart';
import '../domain/reading_plan.dart';
import 'streak_heatmap.dart';

final activePlanProvider = FutureProvider<ActivePlan?>((ref) async {
  return ref.read(plannerRepositoryProvider).getActivePlan();
});

final completedDaysProvider =
    FutureProvider.family<Set<int>, String>((ref, String planKey) async {
  return ref.read(plannerRepositoryProvider).getCompletedDays(planKey);
});

/// Union of reading-plan completion dates and prayer-log dates, for the heatmap.
final activityDatesProvider = FutureProvider<Set<DateTime>>((ref) async {
  final planner = ref.read(plannerRepositoryProvider);
  final dates = <DateTime>{...await planner.completionDates()};
  final logs = await ref.read(progressRepositoryProvider).getRecentPrayerLogs();
  for (final log in logs) {
    final d = DateTime.tryParse(log.dateIso);
    if (d != null) dates.add(DateTime(d.year, d.month, d.day));
  }
  return dates;
});

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ActivePlan?> active = ref.watch(activePlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Planner')),
      body: AppBackdrop(
        child: SafeArea(
          child: active.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace _) => Center(child: Text('Planner error: $e')),
            data: (ActivePlan? plan) => plan == null
                ? _PlanPicker(ref: ref)
                : _ActivePlanView(ref: ref, active: plan),
          ),
        ),
      ),
    );
  }
}

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final List<ReadingPlan> plans = ReadingPlans.summaries();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: <Widget>[
        const SectionHeading(
          title: 'Choose a reading plan',
          subtitle: 'Daily Bible readings with progress tracking',
        ),
        const SizedBox(height: 12),
        ...plans.map((ReadingPlan p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                onTap: () async {
                  await ref.read(plannerRepositoryProvider).startPlan(p.key);
                  ref.invalidate(activePlanProvider);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(p.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(p.subtitle),
                    const SizedBox(height: 4),
                    Text('${p.totalDays} days', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _ActivePlanView extends ConsumerWidget {
  const _ActivePlanView({required this.ref, required this.active});
  final WidgetRef ref;
  final ActivePlan active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReadingPlan plan = ReadingPlans.build(active.planKey);
    final int today = PlannerRepository.currentDayIndex(active.startDate)
        .clamp(0, plan.totalDays - 1);
    final AsyncValue<Set<int>> completed = ref.watch(completedDaysProvider(active.planKey));
    final AsyncValue<Set<DateTime>> activity = ref.watch(activityDatesProvider);
    final Set<int> done = completed.value ?? <int>{};

    Future<void> toggle(int dayIndex, bool value) async {
      await ref.read(plannerRepositoryProvider).setDayDone(active.planKey, dayIndex, value);
      ref.invalidate(completedDaysProvider(active.planKey));
      ref.invalidate(activityDatesProvider);
    }

    final double progress = plan.totalDays == 0 ? 0 : done.length / plan.totalDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: SectionHeading(title: plan.title, subtitle: plan.subtitle)),
            TextButton(
              onPressed: () async {
                await ref.read(plannerRepositoryProvider).stopPlan();
                ref.invalidate(activePlanProvider);
              },
              child: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Progress', style: Theme.of(context).textTheme.titleMedium),
                  Text('${done.length} / ${plan.totalDays} days'),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, minHeight: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text("Today · Day ${today + 1}", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _DayTile(
          day: plan.days[today],
          done: done.contains(today),
          highlight: true,
          onChanged: (bool v) => toggle(today, v),
        ),
        const SizedBox(height: 16),
        Text('Coming up', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List<Widget>.generate(
          (plan.totalDays - today - 1).clamp(0, 5),
          (int i) {
            final int idx = today + 1 + i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DayTile(
                day: plan.days[idx],
                done: done.contains(idx),
                highlight: false,
                onChanged: (bool v) => toggle(idx, v),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GlassCard(
          child: activity.when(
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Could not load activity.'),
            data: (Set<DateTime> dates) => StreakHeatmap(activeDates: dates),
          ),
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.done,
    required this.highlight,
    required this.onChanged,
  });

  final ReadingPlanDay day;
  final bool done;
  final bool highlight;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GlassCard(
      child: Row(
        children: <Widget>[
          Checkbox(value: done, onChanged: (bool? v) => onChanged(v ?? false)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Day ${day.dayIndex + 1}',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  day.label('hi'),
                  style: TextStyle(
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? colors.onSurfaceVariant : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open Bible',
            icon: const Icon(Icons.menu_book),
            onPressed: () => context.go('/tab/bible'),
          ),
        ],
      ),
    );
  }
}
