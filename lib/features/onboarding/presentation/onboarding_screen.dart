import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';

/// Onboarding tour — ported 1:1 (colors, copy, slide order) from the
/// dashboard-web prototype at `dashboard-web/onboarding.html`.
class _OColors {
  static const Color primary = Color(0xFF93452B);
  static const Color primaryLt = Color(0xFFC26040);
  static const Color primaryDeep = Color(0xFF7D3820);
  static const Color cream = Color(0xFFFDF7F2);
  static const Color creamDeep = Color(0xFFEEDDD0);
  static const Color textDark = Color(0xFF2D1A0E);
  static const Color textMid = Color(0xFF6B3D25);
  static const Color textMuted = Color(0xFF9C7460);
}

class _OSlide {
  const _OSlide({
    required this.badge,
    required this.titleHi,
    required this.titleEn,
    required this.desc,
    required this.asset,
    this.centered = false,
  });

  final String badge;
  final String titleHi;
  final String titleEn;
  final String desc;
  final String asset;
  final bool centered;
}

const String _iconDir = 'assets/3d-icons/BG removed icons';

const List<_OSlide> _slides = <_OSlide>[
  _OSlide(
    badge: '🙏 यीशु सहाय',
    titleHi: 'साक्षी वाणी में\nआपका स्वागत है',
    titleEn: 'Welcome to Sakshi Vani',
    desc: 'आपके विश्वास-जीवन का डिजिटल साथी — हिंदी में परमेश्वर के वचन, '
        'प्रार्थना और आराधना के साथ।',
    asset: '$_iconDir/SV_birefnet.png',
  ),
  _OSlide(
    badge: '📖 वचन',
    titleHi: 'प्रभु के वचन में\nप्रतिदिन जीयें',
    titleEn: 'Daily Bible in Hindi & English',
    desc: 'पूरी बाइबल हिंदी और अंग्रेज़ी में पढ़ें। ज़ोर से पढ़ने की सुविधा (TTS) '
        'के साथ — हर अध्याय सुनें और समझें।',
    asset: '$_iconDir/jesus and people_birefnet.png',
  ),
  _OSlide(
    badge: '🤲 प्रार्थना',
    titleHi: 'हर दिन प्रार्थना\nमें जुड़े रहें',
    titleEn: 'Log Your Daily Prayers',
    desc: 'सुबह, शाम या किसी भी समय — अपनी प्रार्थनाएँ दर्ज करें और परमेश्वर के '
        'साथ गहरा संबंध बनाएँ।',
    asset: '$_iconDir/prayer_hands_inspyrenet.png',
  ),
  _OSlide(
    badge: '🎵 भजन',
    titleHi: '350+ आराधना\nके गीत',
    titleEn: 'Hindi Worship Songs',
    desc: 'साक्षी वाणी के भजन संग्रह में सभी पारंपरिक हिंदी आराधना गीत — खोजें, '
        'पढ़ें और गाएँ।',
    asset: '$_iconDir/musical_note_u2net.png',
  ),
  _OSlide(
    badge: '🏛️ कलीसिया',
    titleHi: 'अपनी कलीसिया\nके साथ बढ़ें',
    titleEn: 'Grow With Your Church Family',
    desc: 'चर्च उपस्थिति, दैनिक चिंतन और आध्यात्मिक यात्रा को ट्रैक करें। आपका '
        'विश्वास-साथी हमेशा तैयार है।',
    asset: '$_iconDir/church going family_isnet-general-use.png',
  ),
  _OSlide(
    badge: '✝️ समर्पण',
    titleHi: 'प्रेम और समर्पण\nसे बनाया गया',
    titleEn: 'Made with Love & Devotion',
    desc: 'गोस्सनर लूथरन चर्च के सुशिक्षित युवाओं द्वारा प्रेम से निर्मित। हमारे '
        'लोगों की भक्ति और पवित्र त्रिएक परमेश्वर को समर्पित —\n\n'
        'परमपिता परमेश्वर ✦ परमेश्वर पुत्र यीशु मसीह ✦ परमेश्वर पवित्र आत्मा',
    asset: '$_iconDir/gossnercht.png',
    centered: true,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (mounted) context.go('/');
  }

  void _goTo(int n) {
    final int clamped = n.clamp(0, _slides.length - 1);
    _controller.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  bool get _isLast => _index == _slides.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: _finish,
                    child: const Text(
                      'छोड़ें',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _OColors.textMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: List<Widget>.generate(_slides.length, (int i) {
                      final bool active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? _OColors.primary
                              : _OColors.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${_index + 1} / ${_slides.length}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _OColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slide track ──
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (int i) => setState(() => _index = i),
                itemBuilder: (BuildContext context, int i) => _OSlideView(slide: _slides[i]),
              ),
            ),

            // ── Bottom actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: <Widget>[
                  if (_index > 0) ...<Widget>[
                    GestureDetector(
                      onTap: () => _goTo(_index - 1),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: _OColors.creamDeep,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: _OColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _isLast ? _finish() : _goTo(_index + 1),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[_OColors.primaryLt, _OColors.primaryDeep],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: _OColors.primaryDeep.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _isLast ? 'शुरू करें' : 'अगला',
                              style: const TextStyle(
                                fontFamily: 'NotoSansDevanagari',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isLast ? '🙏' : '→',
                              style: const TextStyle(fontSize: 17, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OSlideView extends StatefulWidget {
  const _OSlideView({required this.slide});

  final _OSlide slide;

  @override
  State<_OSlideView> createState() => _OSlideViewState();
}

class _OSlideViewState extends State<_OSlideView> with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2750),
    )..repeat(reverse: true);
    _floatY = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _OSlide slide = widget.slide;
    final CrossAxisAlignment align =
        slide.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final TextAlign textAlign = slide.centered ? TextAlign.center : TextAlign.start;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          // ── Image stage ──
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        _OColors.primaryLt.withValues(alpha: 0.20),
                        _OColors.primaryLt.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: AnimatedBuilder(
                    animation: _floatY,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.translate(
                        offset: Offset(0, _floatY.value),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      slide.asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Text card ──
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Colors.white, Color(0xFFFEF5ED)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _OColors.primary.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(4, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: align,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[_OColors.primaryLt, _OColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    slide.badge,
                    style: const TextStyle(
                      fontFamily: 'NotoSansDevanagari',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.titleHi,
                  textAlign: textAlign,
                  style: const TextStyle(
                    fontFamily: 'NotoSerifDevanagari',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: _OColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slide.titleEn,
                  textAlign: textAlign,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _OColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  slide.desc,
                  textAlign: textAlign,
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontSize: 14,
                    height: 1.7,
                    color: _OColors.textMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
