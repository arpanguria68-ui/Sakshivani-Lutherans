class BibleVerse {
  const BibleVerse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.language,
  });

  final String id;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String language;

  String get reference => '$book $chapter:$verse';

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      id: json['id'] as String? ?? '',
      book: json['book'] as String? ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 1,
      verse: (json['verse'] as num?)?.toInt() ?? 1,
      text: json['text'] as String? ?? '',
      language: json['language'] as String? ?? 'hi',
    );
  }
}
