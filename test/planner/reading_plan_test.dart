import 'package:flutter_test/flutter_test.dart';
import 'package:sakshi_vani/data/bible/bible_books.dart';
import 'package:sakshi_vani/features/planner/domain/reading_plan.dart';

void main() {
  test('book metadata is 66 books, aligned', () {
    expect(BibleBooks.hindi.length, 66);
    expect(BibleBooks.english.length, 66);
    expect(BibleBooks.chapterCounts.length, 66);
    expect(BibleBooks.chapterCounts.reduce((a, b) => a + b), 1189); // canonical total
  });

  test('plans produce the expected number of days', () {
    expect(ReadingPlans.build('gospels40').totalDays, 40);
    expect(ReadingPlans.build('psalms30').totalDays, 30);
    expect(ReadingPlans.build('nt90').totalDays, 90);
    expect(ReadingPlans.build('wholeYear').totalDays, 365);
  });

  test('segmentation preserves and orders all chapters', () {
    final plan = ReadingPlans.build('gospels40');
    final all = plan.days.expand((d) => d.chapters).toList();
    // Matthew(28)+Mark(16)+Luke(24)+John(21) = 89 chapters.
    expect(all.length, 89);
    expect(all.first.bookIndex, 39); // Matthew
    expect(all.first.chapter, 1);
    expect(all.last.bookIndex, 42); // John
    expect(all.last.chapter, 21);
  });

  test('day label formats single book range', () {
    final plan = ReadingPlans.build('psalms30');
    final label = plan.days.first.label('en');
    expect(label.startsWith('Psalms '), true);
  });
}
