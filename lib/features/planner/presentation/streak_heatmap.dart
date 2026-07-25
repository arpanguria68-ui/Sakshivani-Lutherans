import 'package:flutter/material.dart';

/// A GitHub-style activity heatmap of the last [weeks] weeks. A day is "active"
/// if its date (midnight) is in [activeDates].
class StreakHeatmap extends StatelessWidget {
  const StreakHeatmap({
    super.key,
    required this.activeDates,
    this.weeks = 13,
  });

  final Set<DateTime> activeDates;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DateTime today = _dateOnly(DateTime.now());
    // Start on the Monday of the earliest visible week.
    final int totalDays = weeks * 7;
    final DateTime start = today.subtract(Duration(days: totalDays - 1));

    final List<Widget> columns = <Widget>[];
    for (int w = 0; w < weeks; w++) {
      final List<Widget> cells = <Widget>[];
      for (int d = 0; d < 7; d++) {
        final DateTime day = start.add(Duration(days: w * 7 + d));
        final bool future = day.isAfter(today);
        final bool active = activeDates.contains(day);
        cells.add(Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: future
                ? Colors.transparent
                : active
                    ? colors.primary
                    : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
        ));
      }
      columns.add(Column(children: cells));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
