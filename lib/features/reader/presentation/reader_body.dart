import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final AudioPlayer _pagePlayer = AudioPlayer(playerId: 'page_turn')
    ..setReleaseMode(ReleaseMode.stop);
  List<List<int>> _pages = <List<int>>[];
  int _currentPage = 0;

  void _onPageTurned(int page) {
    setState(() => _currentPage = page);
    if (widget.settings.pageTurnSound) {
      HapticFeedback.selectionClick();
      // Fire-and-forget; ignore playback errors (no engine, muted, etc.).
      _pagePlayer.play(AssetSource('sounds/page_turn.wav'), volume: 0.7).catchError((_) {});
    }
  }

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
    _pagePlayer.dispose();
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
    final Widget content =
        widget.settings.paginated ? _buildPaginated() : _buildScroll();
    if (!widget.settings.paperTexture) {
      return ColoredBox(color: widget.palette.background, child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: widget.palette.background),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _PaperTexturePainter(
                base: widget.palette.background,
                ink: widget.palette.text,
                // E-ink stays nearly flat; sepia/system get a richer grain.
                grain: widget.palette.flat ? 0.012 : 0.05,
                seed: widget.settings.paginated ? _currentPage : 0,
              ),
            ),
          ),
          Positioned.fill(child: content),
        ],
      ),
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
              onPageChanged: _onPageTurned,
              itemBuilder: (BuildContext context, int p) {
                final Widget page = Padding(
                  padding: widget.padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _pages[p].map((int i) => _lineWidget(i, style)).toList(),
                  ),
                );
                return widget.settings.pageFlip
                    ? _flipPage(p, constraints.maxWidth, page)
                    : page;
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

  /// EasyFlipViewPager-style page flip, reimplemented natively: pin the page
  /// against the PageView slide, then rotate it around its inner edge with
  /// perspective. Adjacent pages fade at the edge-on angle to avoid mirroring.
  Widget _flipPage(int p, double width, Widget child) {
    return AnimatedBuilder(
      animation: _pageController,
      child: child,
      builder: (BuildContext context, Widget? c) {
        double page;
        if (_pageController.hasClients &&
            _pageController.position.hasContentDimensions &&
            _pageController.page != null) {
          page = _pageController.page!;
        } else {
          page = _currentPage.toDouble();
        }
        final double value = (p - page).clamp(-1.0, 1.0);
        final bool leaving = value <= 0;
        final Alignment alignment =
            leaving ? Alignment.centerRight : Alignment.centerLeft;
        final double angle = value * (math.pi / 2);
        final double opacity = (1 - value.abs()).clamp(0.0, 1.0);
        final Matrix4 flip = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle);
        return Transform.translate(
          offset: Offset(-value * width, 0),
          child: Opacity(
            opacity: opacity,
            child: Transform(alignment: alignment, transform: flip, child: c),
          ),
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

/// A cheap procedural paper grain: faint deterministic speckle + soft vignette.
/// Deterministic per [seed] so it stays stable within a page (no shimmer on
/// rebuild) but subtly differs page to page.
class _PaperTexturePainter extends CustomPainter {
  _PaperTexturePainter({
    required this.base,
    required this.ink,
    required this.grain,
    required this.seed,
  });

  final Color base;
  final Color ink;
  final double grain;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final math.Random rng = math.Random(seed * 7919 + 17);
    final Paint dot = Paint();
    final int marks =
        ((size.width * size.height) / 1400).clamp(120, 900).toInt();
    for (int i = 0; i < marks; i++) {
      final double dx = rng.nextDouble() * size.width;
      final double dy = rng.nextDouble() * size.height;
      final double a = grain * (0.15 + 0.55 * rng.nextDouble());
      dot.color = ink.withValues(alpha: a);
      final double r = 0.4 + rng.nextDouble() * 0.9;
      canvas.drawCircle(Offset(dx, dy), r, dot);
    }
    // Soft edge vignette for a page-in-hand feel.
    final Paint vignette = Paint()
      ..shader = RadialGradient(
        colors: <Color>[Colors.transparent, ink.withValues(alpha: 0.05)],
        stops: const <double>[0.72, 1.0],
        radius: 0.9,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(_PaperTexturePainter old) =>
      old.base != base || old.ink != ink || old.grain != grain || old.seed != seed;
}
