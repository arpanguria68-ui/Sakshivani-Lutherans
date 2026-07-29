/// How the verse-plate photo background is picked.
enum VerseBackgroundMode { auto, manual }

/// User-configurable verse-plate background: either a fixed photo the user
/// picked, or an auto-rotating slideshow (screensaver-style) over a
/// user-orderable list, changing every [rotateHours].
class VerseBackgroundSettings {
  const VerseBackgroundSettings({
    required this.mode,
    required this.order,
    required this.rotateHours,
    required this.manualImage,
  });

  final VerseBackgroundMode mode;
  final List<String> order;
  final int rotateHours;
  final String manualImage;

  // Note: sunrise.png is excluded — that source file is corrupted
  // (truncated) upstream in the web repo's assets/backgrounds; re-add once
  // it's re-exported.
  static const List<String> defaultOrder = <String>[
    'assets/backgrounds/spring.webp',
    'assets/backgrounds/green_hills.webp',
    'assets/backgrounds/gel_church.webp',
    'assets/backgrounds/monsoon.webp',
    'assets/backgrounds/waterfall.webp',
    'assets/backgrounds/autumn.webp',
    'assets/backgrounds/full_moon.webp',
    'assets/backgrounds/gel_church_sunset.webp',
    'assets/backgrounds/parchment.webp',
    'assets/backgrounds/gel_church_full_view.webp',
    'assets/backgrounds/obsidian.webp',
  ];

  static const int defaultRotateHours = 24;

  static VerseBackgroundSettings initial() => VerseBackgroundSettings(
        mode: VerseBackgroundMode.auto,
        order: defaultOrder,
        rotateHours: defaultRotateHours,
        manualImage: defaultOrder.first,
      );

  VerseBackgroundSettings copyWith({
    VerseBackgroundMode? mode,
    List<String>? order,
    int? rotateHours,
    String? manualImage,
  }) {
    return VerseBackgroundSettings(
      mode: mode ?? this.mode,
      order: order ?? this.order,
      rotateHours: rotateHours ?? this.rotateHours,
      manualImage: manualImage ?? this.manualImage,
    );
  }

  /// Resolves which asset should be shown at [now].
  String resolve(DateTime now) {
    if (mode == VerseBackgroundMode.manual) {
      return manualImage;
    }
    final List<String> cycle = order.isEmpty ? defaultOrder : order;
    final int gapHours = rotateHours <= 0 ? defaultRotateHours : rotateHours;
    final int hoursSinceEpoch = now.toUtc().difference(DateTime.utc(1970)).inHours;
    final int index = (hoursSinceEpoch ~/ gapHours) % cycle.length;
    return cycle[index];
  }
}
