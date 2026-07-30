import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/prayer_log.dart';
import '../../../data/models/reflection_entry.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../home/presentation/home_tab.dart';

/// Journey / progress dashboard — ported 1:1 (colors, layout, copy) from the
/// dashboard-web prototype at `dashboard-web/progress.html`: streak banner,
/// clay stat cards, 7-day activity chart, mood insight and activity feed.
class _JColors {
  static const Color primary = Color(0xFF93452B);
  static const Color secondary = Color(0xFFC17D3C);
  static const Color bible = Color(0xFF4A6FA5);
  static const Color reflect = Color(0xFF76546A);
  static const Color cream = Color(0xFFFDF7F2);
  static const Color creamDeep = Color(0xFFEEDDD0);
  static const Color textDisplay = Color(0xFF2D1A0E);
  static const Color textMuted = Color(0xFF6B3D25);
}

BoxDecoration _clayDecoration({double radius = 20}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[_JColors.cream, _JColors.creamDeep],
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: <BoxShadow>[
      BoxShadow(color: _JColors.primary.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(6, 6)),
      BoxShadow(color: Colors.white.withValues(alpha: 0.84), blurRadius: 10, offset: const Offset(-4, -4)),
    ],
  );
}

class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProgressStats> stats = ref.watch(progressStatsProvider);
    final AsyncValue<List<PrayerLog>> prayerLogs = ref.watch(prayerLogsProvider);
    final AsyncValue<List<ReflectionEntry>> reflections = ref.watch(reflectionsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: <Widget>[
          _StreakBanner(stats: stats),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickLogButton(
                  label: 'Add Prayer',
                  icon: Icons.self_improvement_outlined,
                  onTap: () => _openPrayerLogDialog(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickLogButton(
                  label: 'Add Reflection',
                  icon: Icons.edit_note_outlined,
                  onTap: () => _openReflectionDialog(context, ref),
                ),
              ),
            ],
          ),
          const _SectionLabel('THIS MONTH'),
          _StatsGrid(prayerLogs: prayerLogs, reflections: reflections),
          const _SectionLabel('LAST 7 DAYS'),
          _WeekChart(prayerLogs: prayerLogs, reflections: reflections),
          const _SectionLabel('REFLECTION MOODS'),
          const _MoodCard(),
          const _SectionLabel('RECENT ACTIVITY'),
          _ActivityFeed(prayerLogs: prayerLogs, reflections: reflections),
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

// ── Streak banner ──────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.stats});

  final AsyncValue<ProgressStats> stats;

  @override
  Widget build(BuildContext context) {
    final int streak = stats.maybeWhen(data: (ProgressStats s) => s.currentStreak, orElse: () => 0);
    final String badge = switch (streak) {
      >= 30 => '🏆 Month+',
      >= 14 => '⭐ 2 Weeks',
      >= 7 => '🌟 1 Week',
      >= 3 => '✨ Growing',
      > 0 => '$streak day${streak > 1 ? 's' : ''}',
      _ => 'Start Today',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_JColors.primary, _JColors.secondary],
        ),
      ),
      child: Row(
        children: <Widget>[
          const Text('🔥', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('$streak',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(streak == 1 ? 'day streak' : 'days streak',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.82))),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  const _QuickLogButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: _JColors.creamDeep,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 16, color: _JColors.primary),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _JColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: _JColors.textMuted,
        ),
      ),
    );
  }
}

// ── Stats grid ──────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.prayerLogs, required this.reflections});

  final AsyncValue<List<PrayerLog>> prayerLogs;
  final AsyncValue<List<ReflectionEntry>> reflections;

  bool _isThisMonth(DateTime d) {
    final DateTime now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final List<PrayerLog> prayers = prayerLogs.maybeWhen(data: (List<PrayerLog> v) => v, orElse: () => const <PrayerLog>[]);
    final List<ReflectionEntry> reflects = reflections.maybeWhen(data: (List<ReflectionEntry> v) => v, orElse: () => const <ReflectionEntry>[]);

    final int prayerMonth = prayers.where((PrayerLog p) => _isThisMonth(DateTime.tryParse(p.dateIso) ?? DateTime(2000))).length;
    final int reflectMonth = reflects.where((ReflectionEntry r) => _isThisMonth(DateTime.tryParse(r.dateIso) ?? DateTime(2000))).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: <Widget>[
        _StatCard(
          asset: 'assets/3d-icons/prayer_hands.png',
          tint: _JColors.primary,
          value: '$prayerMonth',
          label: 'Prayers',
          sub: '${prayers.length} total',
        ),
        _StatCard(
          asset: 'assets/3d-icons/holy_bible.png',
          tint: _JColors.bible,
          value: '0',
          label: 'Bible Sessions',
          sub: 'this month',
        ),
        _StatCard(
          asset: 'assets/3d-icons/lutheran_church.png',
          tint: _JColors.secondary,
          value: '0',
          label: 'Church Visits',
          sub: 'this month',
        ),
        _StatCard(
          asset: 'assets/3d-icons/journal_notebook.png',
          tint: _JColors.reflect,
          value: '$reflectMonth',
          label: 'Reflections',
          sub: '${reflects.length} total',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.asset,
    required this.tint,
    required this.value,
    required this.label,
    required this.sub,
  });

  final String asset;
  final Color tint;
  final String value;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _clayDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Image.asset(asset, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.circle, color: tint, size: 18)),
            ),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: tint, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 12, color: _JColors.textMuted, fontWeight: FontWeight.w500)),
          Text(sub, style: TextStyle(fontSize: 10, color: _JColors.textMuted.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

// ── 7-day chart ───────────────────────────────────────────────────────────

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.prayerLogs, required this.reflections});

  final AsyncValue<List<PrayerLog>> prayerLogs;
  final AsyncValue<List<ReflectionEntry>> reflections;

  static const List<String> _dayLabels = <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final List<PrayerLog> prayers = prayerLogs.maybeWhen(data: (List<PrayerLog> v) => v, orElse: () => const <PrayerLog>[]);
    final List<ReflectionEntry> reflects = reflections.maybeWhen(data: (List<ReflectionEntry> v) => v, orElse: () => const <ReflectionEntry>[]);

    final DateTime today = DateTime.now();
    final DateTime todayMidnight = DateTime(today.year, today.month, today.day);
    final List<DateTime> days = List<DateTime>.generate(7, (int i) => todayMidnight.subtract(Duration(days: 6 - i)));

    int prayerCountFor(DateTime d) => prayers.where((PrayerLog p) {
          final DateTime? pd = DateTime.tryParse(p.dateIso);
          return pd != null && pd.year == d.year && pd.month == d.month && pd.day == d.day;
        }).length;
    int reflectCountFor(DateTime d) => reflects.where((ReflectionEntry r) {
          final DateTime? rd = DateTime.tryParse(r.dateIso);
          return rd != null && rd.year == d.year && rd.month == d.month && rd.day == d.day;
        }).length;

    int maxEvents = 1;
    for (final DateTime d in days) {
      final int total = prayerCountFor(d) + reflectCountFor(d);
      if (total > maxEvents) maxEvents = total;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _clayDecoration(),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('Daily Activity',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _JColors.textDisplay)),
              const Spacer(),
              const _Legend(color: _JColors.primary, label: 'Pray'),
              const SizedBox(width: 8),
              const _Legend(color: _JColors.reflect, label: 'Journal'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(7, (int i) {
                final DateTime d = days[i];
                final int p = prayerCountFor(d);
                final int r = reflectCountFor(d);
                final bool isToday = i == 6;

                Widget bar(Color color, int count) {
                  final double h = count == 0 ? 0 : (count / maxEvents * 60).clamp(6, 60);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    height: h,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  );
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: (p == 0 && r == 0)
                                ? <Widget>[
                                    Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: _JColors.creamDeep,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ]
                                : <Widget>[
                                    if (p > 0) bar(_JColors.primary, p),
                                    if (r > 0) bar(_JColors.reflect, r),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isToday ? 'Today' : _dayLabels[d.weekday % 7],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                            color: isToday ? _JColors.primary : _JColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _JColors.textMuted)),
      ],
    );
  }
}

// ── Mood card (no mood field is tracked yet — mirrors prototype's own
// empty state, shown until reflection mood tagging exists) ────────────────

class _MoodCard extends StatelessWidget {
  const _MoodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _clayDecoration(),
      child: Column(
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('How have you been feeling?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _JColors.textDisplay)),
          ),
          const SizedBox(height: 14),
          Text(
            'Start journaling to see your mood trends.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _JColors.textMuted.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity feed ───────────────────────────────────────────────────

class _FeedItem {
  const _FeedItem({required this.type, required this.title, required this.sub, required this.date, required this.asset});

  final String type;
  final String title;
  final String sub;
  final DateTime date;
  final String asset;
}

class _ActivityFeed extends ConsumerWidget {
  const _ActivityFeed({required this.prayerLogs, required this.reflections});

  final AsyncValue<List<PrayerLog>> prayerLogs;
  final AsyncValue<List<ReflectionEntry>> reflections;

  String _relTime(DateTime d) {
    final int days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PrayerLog> prayers = prayerLogs.maybeWhen(data: (List<PrayerLog> v) => v, orElse: () => const <PrayerLog>[]);
    final List<ReflectionEntry> reflects = reflections.maybeWhen(data: (List<ReflectionEntry> v) => v, orElse: () => const <ReflectionEntry>[]);

    final List<_FeedItem> items = <_FeedItem>[
      ...prayers.map((PrayerLog p) => _FeedItem(
            type: 'prayer',
            title: 'Prayer logged (x${p.count})',
            sub: p.notes,
            date: DateTime.tryParse(p.dateIso) ?? DateTime.now(),
            asset: 'assets/3d-icons/prayer_hands.png',
          )),
      ...reflects.map((ReflectionEntry r) => _FeedItem(
            type: 'reflect',
            title: r.verse.isEmpty ? 'Reflection' : r.verse,
            sub: r.text.length > 60 ? '${r.text.substring(0, 60)}…' : r.text,
            date: DateTime.tryParse(r.dateIso) ?? DateTime.now(),
            asset: 'assets/3d-icons/journal_notebook.png',
          )),
    ]..sort((_FeedItem a, _FeedItem b) => b.date.compareTo(a.date));

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: _clayDecoration(),
        child: Column(
          children: <Widget>[
            const Text('🌱', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No activity yet.\nStart logging prayers or reflections to see your journey here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: _JColors.textMuted.withValues(alpha: 0.9), height: 1.5),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.take(15).map((_FeedItem item) {
        final Color tint = item.type == 'prayer' ? _JColors.primary : _JColors.reflect;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _clayDecoration(radius: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(item.asset, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 14, color: tint)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _JColors.textDisplay)),
                    if (item.sub.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(item.sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: _JColors.textMuted.withValues(alpha: 0.9))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_relTime(item.date),
                  style: TextStyle(fontSize: 10.5, color: _JColors.textMuted.withValues(alpha: 0.7))),
            ],
          ),
        );
      }).toList(growable: false),
    );
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
