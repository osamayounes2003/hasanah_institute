import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Brand splash with a staged Quranic verse reveal.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    this.statusMessage = 'جاري الاتصال بقاعدة البيانات...',
    this.showProgress = true,
    super.key,
  });

  final String statusMessage;
  final bool showProgress;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _verse =
      '﴿وَأَنَّ الْمَسَاجِدَ لِلَّهِ فَلَا تَدْعُوا مَعَ اللَّهِ أَحَدًا﴾';

  late final AnimationController _verseController;
  late final AnimationController _glowController;
  late final AnimationController _footerController;

  late final Animation<double> _verseFade;
  late final Animation<Offset> _verseSlide;
  late final Animation<double> _verseScale;
  late final Animation<double> _glow;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _verseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _verseFade = CurvedAnimation(
      parent: _verseController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _verseSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _verseController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _verseScale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _verseController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _glow = Tween<double>(begin: 0.2, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _footerFade = CurvedAnimation(
      parent: _footerController,
      curve: Curves.easeOut,
    );

    _verseController.forward();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _footerController.forward();
    });
  }

  @override
  void dispose() {
    _verseController.dispose();
    _glowController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B3F3A),
                Color(0xFF0F766E),
                Color(0xFF115E59),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _verseFade,
                    child: SlideTransition(
                      position: _verseSlide,
                      child: ScaleTransition(
                        scale: _verseScale,
                        child: AnimatedBuilder(
                          animation: _glow,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: HasanahColors.accent.withValues(
                                      alpha: _glow.value * 0.28,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ornamentLine(),
                              const SizedBox(height: 28),
                              Text(
                                _verse,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.notoKufiArabic(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 2.0,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'سورة الجن — آية ١٨',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoKufiArabic(
                                  color: const Color(0xFFE7C76A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _ornamentLine(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _footerFade,
                    child: Column(
                      children: [
                        if (widget.showProgress) ...[
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white.withValues(alpha: 0.85),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          widget.statusMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ornamentLine() {
    return Container(
      width: 88,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            HasanahColors.accent.withValues(alpha: 0.95),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
