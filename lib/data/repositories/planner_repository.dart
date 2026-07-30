import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';

class ActivePlan {
  const ActivePlan({required this.planKey, required this.startDate});
  final String planKey;
  final DateTime startDate;
}

class PlannerRepository {
  PlannerRepository(this._database);

  final AppDatabase _database;

  Future<ActivePlan?> getActivePlan() async {
    final rows = await _database.db.query('active_plan', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    final Map<String, Object?> r = rows.first;
    final DateTime? start = DateTime.tryParse(r['start_iso'] as String? ?? '');
    if (start == null) return null;
    return ActivePlan(planKey: r['plan_key'] as String, startDate: start);
  }

  /// Start (or switch to) a plan. Preserves prior completions for that plan so
  /// the user resumes where they left off; resets the start date to today.
  Future<void> startPlan(String planKey) async {
    final DateTime today = _dateOnly(DateTime.now());
    await _database.db.insert(
      'active_plan',
      <String, Object?>{'id': 1, 'plan_key': planKey, 'start_iso': today.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> stopPlan() async {
    await _database.db.delete('active_plan', where: 'id = 1');
  }

  Future<Set<int>> getCompletedDays(String planKey) async {
    final rows = await _database.db.query(
      'plan_completions',
      columns: <String>['day_index'],
      where: 'plan_key = ?',
      whereArgs: <Object?>[planKey],
    );
    return rows.map((r) => r['day_index'] as int).toSet();
  }

  Future<void> setDayDone(String planKey, int dayIndex, bool done) async {
    if (done) {
      await _database.db.insert(
        'plan_completions',
        <String, Object?>{
          'plan_key': planKey,
          'day_index': dayIndex,
          'done_iso': _dateOnly(DateTime.now()).toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _database.db.delete(
        'plan_completions',
        where: 'plan_key = ? AND day_index = ?',
        whereArgs: <Object?>[planKey, dayIndex],
      );
    }
  }

  /// All completion dates (any plan) — for the activity heatmap.
  Future<List<DateTime>> completionDates() async {
    final rows = await _database.db.query('plan_completions', columns: <String>['done_iso']);
    return rows
        .map((r) => DateTime.tryParse(r['done_iso'] as String? ?? ''))
        .whereType<DateTime>()
        .map(_dateOnly)
        .toList(growable: false);
  }

  /// Day index the plan is "on" today (0-based), given its start date.
  static int currentDayIndex(DateTime startDate) {
    final DateTime a = _dateOnly(startDate);
    final DateTime b = _dateOnly(DateTime.now());
    return b.difference(a).inDays;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
