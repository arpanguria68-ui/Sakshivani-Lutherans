import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/reader_settings_controller.dart';
import '../domain/reader_settings.dart';

Future<void> showReaderSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) => const _ReaderSettingsSheet(),
  );
}

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReaderSettings s = ref.watch(readerSettingsControllerProvider);
    final ReaderSettingsController c =
        ref.read(readerSettingsControllerProvider.notifier);
    final TextTheme text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Reading settings', style: text.titleLarge),
              const SizedBox(height: 12),

              _sliderRow(
                label: 'Text size',
                value: s.fontSize,
                min: ReaderSettings.minFontSize,
                max: ReaderSettings.maxFontSize,
                display: s.fontSize.toInt().toString(),
                onChanged: c.setFontSize,
              ),
              _sliderRow(
                label: 'Line spacing',
                value: s.lineHeight,
                min: 1.2,
                max: 2.4,
                display: s.lineHeight.toStringAsFixed(2),
                onChanged: c.setLineHeight,
              ),
              _sliderRow(
                label: 'Letter spacing',
                value: s.letterSpacing,
                min: 0,
                max: 4,
                display: s.letterSpacing.toStringAsFixed(1),
                onChanged: c.setLetterSpacing,
              ),
              _sliderRow(
                label: 'Word spacing',
                value: s.wordSpacing,
                min: 0,
                max: 10,
                display: s.wordSpacing.toStringAsFixed(0),
                onChanged: c.setWordSpacing,
              ),

              const SizedBox(height: 8),
              _label('Font'),
              SegmentedButton<ReaderFontFamily>(
                segments: const <ButtonSegment<ReaderFontFamily>>[
                  ButtonSegment<ReaderFontFamily>(
                      value: ReaderFontFamily.serif, label: Text('Serif')),
                  ButtonSegment<ReaderFontFamily>(
                      value: ReaderFontFamily.sans, label: Text('Sans')),
                ],
                selected: <ReaderFontFamily>{s.font},
                onSelectionChanged: (Set<ReaderFontFamily> v) => c.setFont(v.first),
              ),

              const SizedBox(height: 12),
              _label('Alignment'),
              SegmentedButton<ReaderAlign>(
                segments: const <ButtonSegment<ReaderAlign>>[
                  ButtonSegment<ReaderAlign>(
                      value: ReaderAlign.start, icon: Icon(Icons.format_align_left)),
                  ButtonSegment<ReaderAlign>(
                      value: ReaderAlign.center, icon: Icon(Icons.format_align_center)),
                  ButtonSegment<ReaderAlign>(
                      value: ReaderAlign.justify, icon: Icon(Icons.format_align_justify)),
                ],
                selected: <ReaderAlign>{s.align},
                onSelectionChanged: (Set<ReaderAlign> v) => c.setAlign(v.first),
              ),

              const SizedBox(height: 12),
              _label('Reading theme'),
              SegmentedButton<ReaderTheme>(
                segments: const <ButtonSegment<ReaderTheme>>[
                  ButtonSegment<ReaderTheme>(
                      value: ReaderTheme.system, label: Text('App')),
                  ButtonSegment<ReaderTheme>(
                      value: ReaderTheme.sepia, label: Text('Sepia')),
                  ButtonSegment<ReaderTheme>(
                      value: ReaderTheme.eink, label: Text('E‑ink')),
                ],
                selected: <ReaderTheme>{s.theme},
                onSelectionChanged: (Set<ReaderTheme> v) => c.setTheme(v.first),
              ),

              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Page mode (tap to turn)'),
                subtitle: const Text('Paper-like paginated reading; ideal with E‑ink'),
                value: s.paginated,
                onChanged: c.setPaginated,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Paper texture'),
                subtitle: const Text('Subtle grain on the reading surface'),
                value: s.paperTexture,
                onChanged: c.setPaperTexture,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Page-turn sound & haptics'),
                subtitle: const Text('A soft rustle + tap when turning pages'),
                value: s.pageTurnSound,
                onChanged: c.setPageTurnSound,
              ),

              const SizedBox(height: 4),
              _sliderRow(
                label: 'Read-aloud speed',
                value: s.ttsRate,
                min: 0.25,
                max: 0.85,
                display: '${(s.ttsRate / 0.5).toStringAsFixed(1)}x',
                onChanged: c.setTtsRate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(display),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
