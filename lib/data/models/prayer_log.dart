class PrayerLog {
  const PrayerLog({
    required this.id,
    required this.dateIso,
    required this.count,
    required this.notes,
  });

  final int id;
  final String dateIso;
  final int count;
  final String notes;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'date_iso': dateIso,
      'count': count,
      'notes': notes,
    };
  }

  factory PrayerLog.fromMap(Map<String, Object?> map) {
    return PrayerLog(
      id: (map['id'] as num).toInt(),
      dateIso: map['date_iso'] as String? ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
    );
  }
}
