import 'package:flutter/material.dart';

import '../domain/reader_settings.dart';

/// Renders reader content in one of two modes driven by [settings.paginated]:
///  - scroll  : a normal vertical scroll view (default).
///  - eink     : measured, tap-to-turn pages (no scrolling, flat surface).
///
/// In both modes the [activeLine] (TTS) is highlighted; in paginated mode the
/// view auto-turns to the page containing the active line.
class ReaderBody extends StatefulWidget {
  const ReaderBody({
    super.key,
    required this.lines,
    required this.settings,
    required this.palette,
    this.activeLine,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  final List<String> lines;
  final ReaderSettings settings;
  final ReaderPalette palette;
  final int? activeLine;
  final EdgeInsets padding;

  @override
  State<ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<ReaderBody> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = <int, GlobalKey>{};
  List<List<int>> _pages = <List<int>>[];
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant ReaderBody old) {
    super.didUpdateWidget(old);
    if (widget.activeLine != old.activeLine && widget.activeLine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealActiveLine());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _revealActiveLine() {
    final int? line = widget.activeLine;
    if (line == null) return;
    if (widget.settings.paginated) {
      for (int p = 0; p < _pages.length; p++) {
        if (_pages[p].contains(line)) {
          if (p != _currentPage && _pageController.hasClients) {
            _pageController.animateToPage(p,
                duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
          }
          break;
        }
      }
    } else {
      final GlobalKey? key = _lineKeys[line];
      final BuildContext? ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.3,
            curve: Curves.easeOut);
      }
    }
  }

  TextStyle _textStyle() {
    final ReaderSettings s = widget.settings;
    return TextStyle(
      fontFamily: s.fontFamily,
      fontSize: s.fontSize,
      height: s.lineHeight,
      letterSpacing: s.letterSpacing,
      wordSpacing: s.wordSpacing,
      color: widget.palette.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.palette.background,
      child: widget.settings.paginated ? _buildPaginated() : _buildScroll(),
    );
  }

  Widget _buildScroll() {
    final TextStyle style = _textStyle();
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.lines.length,
      itemBuilder: (BuildContext context, int i) => _lineWidget(i, style),
    );
  }

  Widget _lineWidget(int i, TextStyle style) {
    final bool active = widget.activeLine == i;
    _lineKeys.putIfAbsent(i, () => GlobalKey());
    final String text = widget.lines[i];
    return Container(
      key: _lineKeys[i],
      width: double.infinity,
      decoration: active
          ? BoxDecoration(
              color: widget.palette.highlight,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      child: Text(
        text.isEmpty ? ' ' : text,
        style: style,
        textAlign: widget.settings.textAlign,
      ),
    );
  }

  Widget _buildPaginated() {
    final TextStyle style = _textStyle();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _pages = _paginate(constraints, style);
        if (_pages.isEmpty) {
          return const SizedBox.shrink();
        }
        return Stack(
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (int p) => setState(() => _currentPage = p),
              itemBuilder: (BuildContext context, int p) {
                return Padding(
                  padding: widget.padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _pages[p].map((int i) => _lineWidget(i, style)).toList(),
                  ),
                );
              },
            ),
            // Tap zones: left third = previous page, right third = next page.
            Positioned.fill(child: _tapZones()),
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_currentPage + 1} / ${_pages.length}',
                  style: TextStyle(color: widget.palette.subtle, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tapZones() {
    return Row(
      children: <Widget>[
        Expanded(child: GestureDetector(onTap: _prevPage, behavior: HitTestBehavior.translucent)),
        const Expanded(child: SizedBox()),
        Expanded(child: GestureDetector(onTap: _nextPage, behavior: HitTestBehavior.translucent)),
      ],
    );
  }

  void _prevPage() {
    if (_currentPage > 0 && _pageController.hasClients) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1 && _pageController.hasClients) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  /// Greedily pack whole lines into pages that fit the available height.
  List<List<int>> _paginate(BoxConstraints constraints, TextStyle style) {
    final double maxWidth = constraints.maxWidth - widget.padding.horizontal;
    // Reserve space for the page indicator + a small safety margin.
    final double maxHeight =
        constraints.maxHeight - widget.padding.vertical - 28;
    final List<List<int>> pages = <List<int>>[];
    List<int> current = <int>[];
    double used = 0;

    for (int i = 0; i < widget.lines.length; i++) {
      final double h = _measureLineHeight(widget.lines[i], style, maxWidth);
      if (current.isNotEmpty && used + h > maxHeight) {
        pages.add(current);
        current = <int>[];
        used = 0;
      }
      current.add(i);
      used += h;
    }
    if (current.isNotEmpty) pages.add(current);
    return pages;
  }

  double _measureLineHeight(String line, TextStyle style, double maxWidth) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: line.isEmpty ? ' ' : line, style: style),
      textDirection: TextDirection.ltr,
      textAlign: widget.settings.textAlign,
    )..layout(maxWidth: maxWidth > 0 ? maxWidth : 1);
    // +2 for the per-line vertical padding used in _lineWidget.
    return tp.height + 2;
  }
}
