import '../../../data/bible/bible_books.dart';

/// A single chapter reference (0-based book, 1-based chapter).
class ChapterRef {
  const ChapterRef(this.bookIndex, this.chapter);
  final int bookIndex;
  final int chapter;
}

/// One day's assignment in a reading plan.
class ReadingPlanDay {
  const ReadingPlanDay(this.dayIndex, this.chapters);
  final int dayIndex;
  final List<ChapterRef> chapters;

  /// Human label, e.g. "मत्ती 1–3" or spanning "मत्ती 28 – मरकुस 2".
  String label(String language) {
    if (chapters.isEmpty) return '';
    final ChapterRef first = chapters.first;
    final ChapterRef last = chapters.last;
    if (first.bookIndex == last.bookIndex) {
      final String book = BibleBooks.name(first.bookIndex, language);
      return first.chapter == last.chapter
          ? '$book ${first.chapter}'
          : '$book ${first.chapter}–${last.chapter}';
    }
    final String b1 = BibleBooks.name(first.bookIndex, language);
    final String b2 = BibleBooks.name(last.bookIndex, language);
    return '$b1 ${first.chapter} – $b2 ${last.chapter}';
  }
}

class ReadingPlan {
  const ReadingPlan({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.days,
  });

  final String key;
  final String title;
  final String subtitle;
  final List<ReadingPlanDay> days;

  int get totalDays => days.length;
}

class ReadingPlans {
  const ReadingPlans._();

  /// Flatten [bookStart, bookEnd] (inclusive) into a chapter sequence.
  static List<ChapterRef> _flatten(int bookStart, int bookEnd) {
    final List<ChapterRef> out = <ChapterRef>[];
    for (int b = bookStart; b <= bookEnd; b++) {
      final int count = BibleBooks.chapterCounts[b];
      for (int c = 1; c <= count; c++) {
        out.add(ChapterRef(b, c));
      }
    }
    return out;
  }

  /// Segment [chapters] into [dayCount] roughly-equal days (by chapter count).
  static List<ReadingPlanDay> _segment(List<ChapterRef> chapters, int dayCount) {
    final List<ReadingPlanDay> days = <ReadingPlanDay>[];
    if (chapters.isEmpty || dayCount <= 0) return days;
    final int total = chapters.length;
    for (int d = 0; d < dayCount; d++) {
      final int start = (d * total) ~/ dayCount;
      final int end = ((d + 1) * total) ~/ dayCount;
      if (end <= start) continue;
      days.add(ReadingPlanDay(days.length, chapters.sublist(start, end)));
    }
    return days;
  }

  static ReadingPlan build(String key) {
    switch (key) {
      case 'gospels40':
        return ReadingPlan(
          key: key,
          title: 'Gospels in 40 days',
          subtitle: 'Matthew · Mark · Luke · John',
          days: _segment(_flatten(39, 42), 40),
        );
      case 'psalms30':
        return ReadingPlan(
          key: key,
          title: 'Psalms in 30 days',
          subtitle: 'भजन संहिता · a psalm-set each day',
          days: _segment(_flatten(18, 18), 30),
        );
      case 'nt90':
        return ReadingPlan(
          key: key,
          title: 'New Testament in 90 days',
          subtitle: 'Matthew → Revelation',
          days: _segment(_flatten(BibleBooks.ntStartIndex, 65), 90),
        );
      case 'wholeYear':
      default:
        return ReadingPlan(
          key: 'wholeYear',
          title: 'Whole Bible in a year',
          subtitle: 'Genesis → Revelation · 365 days',
          days: _segment(_flatten(0, 65), 365),
        );
    }
  }

  static const List<String> allKeys = <String>[
    'gospels40',
    'psalms30',
    'nt90',
    'wholeYear',
  ];

  static List<ReadingPlan> summaries() =>
      allKeys.map(build).toList(growable: false);
}
