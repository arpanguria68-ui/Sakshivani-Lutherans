import '../../core/constants/app_constants.dart';

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.lyrics,
    required this.category,
    this.reference,
    this.book = AppConstants.bookSakshivani,
  });

  final int id;
  final String title;
  final String lyrics;
  final String category;
  final String? reference;

  /// Which song book this belongs to (bookSakshivani / bookDurang).
  final String book;

  factory Song.fromDb(Map<String, Object?> map) {
    return Song(
      id: (map['song_id'] as num).toInt(),
      title: map['title'] as String? ?? '',
      lyrics: map['lyrics'] as String? ?? '',
      category: map['category'] as String? ?? '',
      reference: map['reference'] as String?,
      book: AppConstants.bookSakshivani,
    );
  }

  factory Song.fromDurangJson(Map<String, dynamic> map) {
    return Song(
      id: (map['song_id'] as num).toInt(),
      title: map['title'] as String? ?? '',
      lyrics: map['lyrics'] as String? ?? '',
      category: map['category'] as String? ?? AppConstants.bookDurangLabel,
      reference: map['reference'] as String?,
      book: AppConstants.bookDurang,
    );
  }
}
