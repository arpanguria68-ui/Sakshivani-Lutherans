import 'package:flutter/material.dart';

/// Renders [text] with any occurrences of [terms] emphasized.
///
/// Matching is case-insensitive on the raw string. Terms are the normalized
/// tokens the search engine reports as matched; we highlight their literal
/// occurrences (good enough for Latin and Devanagari alike).
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.terms,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final Set<String> terms;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = style ?? DefaultTextStyle.of(context).style;
    final TextStyle hl = highlightStyle ??
        baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        );

    final List<_Range> ranges = _matchRanges();
    if (ranges.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: overflow);
    }

    final List<TextSpan> spans = <TextSpan>[];
    int cursor = 0;
    for (final _Range r in ranges) {
      if (r.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, r.start), style: baseStyle));
      }
      spans.add(TextSpan(text: text.substring(r.start, r.end), style: hl));
      cursor = r.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }

  List<_Range> _matchRanges() {
    if (terms.isEmpty || text.isEmpty) return const <_Range>[];
    final String lower = text.toLowerCase();
    final List<_Range> raw = <_Range>[];
    for (final String term in terms) {
      final String t = term.toLowerCase().trim();
      if (t.length < 2) continue;
      int from = 0;
      while (true) {
        final int idx = lower.indexOf(t, from);
        if (idx < 0) break;
        raw.add(_Range(idx, idx + t.length));
        from = idx + t.length;
      }
    }
    if (raw.isEmpty) return const <_Range>[];
    raw.sort((_Range a, _Range b) => a.start.compareTo(b.start));

    // Merge overlapping ranges.
    final List<_Range> merged = <_Range>[raw.first];
    for (int i = 1; i < raw.length; i++) {
      final _Range last = merged.last;
      final _Range cur = raw[i];
      if (cur.start <= last.end) {
        merged[merged.length - 1] =
            _Range(last.start, cur.end > last.end ? cur.end : last.end);
      } else {
        merged.add(cur);
      }
    }
    return merged;
  }
}

class _Range {
  const _Range(this.start, this.end);
  final int start;
  final int end;
}
