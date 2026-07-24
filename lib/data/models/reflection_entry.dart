class ReflectionEntry {
  const ReflectionEntry({
    required this.id,
    required this.text,
    required this.verse,
    required this.dateIso,
    required this.isPrivate,
    required this.synced,
    required this.updatedAt,
  });

  final String id;
  final String text;
  final String verse;
  final String dateIso;
  final bool isPrivate;
  final bool synced;
  final String updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'text': text,
      'verse': verse,
      'date_iso': dateIso,
      'is_private': isPrivate ? 1 : 0,
      'synced': synced ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  factory ReflectionEntry.fromMap(Map<String, Object?> map) {
    return ReflectionEntry(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      verse: map['verse'] as String? ?? '',
      dateIso: map['date_iso'] as String? ?? '',
      isPrivate: ((map['is_private'] as num?)?.toInt() ?? 1) == 1,
      synced: ((map['synced'] as num?)?.toInt() ?? 0) == 1,
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
