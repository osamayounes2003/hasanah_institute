import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/circle_session_entities.dart';

/// Five segments in **clockwise** order; index 0 is centered under the top pointer
/// when rotation turns = 0.
const wheelCategories = <QuestionCategory>[
  QuestionCategory.aqeedah,
  QuestionCategory.fiqh,
  QuestionCategory.seerah,
  QuestionCategory.akhlaq,
  QuestionCategory.quran,
];

class IslamicKnowledgeWheel extends StatefulWidget {
  const IslamicKnowledgeWheel({
    required this.onSpinComplete,
    this.enabled = true,
    super.key,
  });

  final Future<void> Function(QuestionCategory category) onSpinComplete;
  final bool enabled;

  @override
  State<IslamicKnowledgeWheel> createState() => _IslamicKnowledgeWheelState();
}

class _IslamicKnowledgeWheelState extends State<IslamicKnowledgeWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotation;
  bool _spinning = false;

  /// Absolute clockwise turns of the wheel (can grow forever).
  double _turns = 0;

  static const _spinDuration = Duration(seconds: 3);
  static final int _count = wheelCategories.length;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _spinDuration);
    _rotation = AlwaysStoppedAnimation(_turns);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Positive [turns] = clockwise (same as [Transform.rotate]).
  /// Returns the category whose **center** is under the top pointer.
  static QuestionCategory categoryUnderPointer(double turns) {
    final n = _normalize(turns);
    // Clockwise rotation by n moves previous indices under the pointer.
    final index = ((-_count * n).round() % _count + _count) % _count;
    return wheelCategories[index];
  }

  /// Normalized turns in [0, 1).
  static double _normalize(double turns) {
    var n = turns % 1;
    if (n < 0) n += 1;
    return n;
  }

  /// Absolute normalized angle that centers [index] under the top pointer.
  static double _targetModForIndex(int index) {
    // From rotation 0 (index 0 on top): CW by k segments → index (count-k)%count.
    // So for [index]: k = (count - index) % count.
    return ((_count - index) % _count) / _count;
  }

  Future<void> _spin() async {
    if (_spinning || !widget.enabled) return;
    setState(() => _spinning = true);

    final random = math.Random();
    final landingIndex = random.nextInt(_count);
    final extraTurns = 4 + random.nextInt(3); // 4–6 full spins
    final targetMod = _targetModForIndex(landingIndex);

    final begin = _turns;
    // Land on targetMod after at least [extraTurns] full rotations from begin.
    var end = begin + extraTurns;
    final endMod = _normalize(end);
    var delta = targetMod - endMod;
    if (delta < 0) delta += 1;
    end += delta;
    // Guarantees a visible spin even if we were already on that segment.
    if (end - begin < extraTurns) {
      end += 1;
    }

    _rotation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.reset();
    await _controller.forward();
    _turns = end;
    // Freeze visual on the exact final angle (avoids rebuild drift).
    _rotation = AlwaysStoppedAnimation(_turns);
    if (!mounted) return;

    // Category from final visual angle — always matches the pointer.
    final category = categoryUnderPointer(_turns);
    setState(() => _spinning = false);
    await widget.onSpinComplete(category);
  }

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.sizeOf(context).width - 32, 340.0);
    final wheelSize = size * 0.9;

    // Force LTR so RTL app direction never mirrors the wheel geometry.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size + 28,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (_spinning || !widget.enabled) ? null : _spin,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 28,
                    child: Container(
                      width: wheelSize + 8,
                      height: wheelSize + 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFD4AF37).withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 32,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotation.value * 2 * math.pi,
                          child: child,
                        );
                      },
                      child: CustomPaint(
                        size: Size.square(wheelSize),
                        painter: _FiveSegmentWheelPainter(),
                      ),
                    ),
                  ),
                  // Fixed pointer: tip sits on the top rim center.
                  const Positioned(
                    top: 0,
                    child: CustomPaint(
                      size: Size(36, 40),
                      painter: _PointerPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              for (final category in wheelCategories)
                Chip(
                  label: Text(
                    category.label,
                    style: const TextStyle(fontSize: 12),
                    textDirection: TextDirection.rtl,
                  ),
                  backgroundColor: _FiveSegmentWheelPainter
                      .colors[category.index]
                      .withValues(alpha: 0.18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (_spinning || !widget.enabled) ? null : _spin,
            icon: _spinning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.replay_circle_filled_outlined),
            label: Text(
              _spinning ? 'تدور العجلة...' : 'تدوير العجلة (3 ثوانٍ)',
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Offset(size.width / 2, size.height);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(0, 8)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, 8)
      ..close();
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE082), Color(0xFFD4AF37), Color(0xFF8B6914)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF5C3B00),
    );
    canvas.drawCircle(
      Offset(size.width / 2, 10),
      4,
      Paint()..color = HasanahColors.secondary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FiveSegmentWheelPainter extends CustomPainter {
  static const colors = [
    Color(0xFF0F766E), // العقيدة
    Color(0xFF7C3AED), // الفقه
    Color(0xFFB45309), // السيرة
    Color(0xFFBE123C), // الأخلاق
    Color(0xFF0369A1), // القرآن
  ];

  static const icons = [
    Icons.brightness_2_outlined,
    Icons.balance_outlined,
    Icons.mosque_outlined,
    Icons.favorite_outline,
    Icons.menu_book_outlined,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final count = wheelCategories.length;
    final sweep = 2 * math.pi / count;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFFD4AF37),
    );

    final rect = Rect.fromCircle(center: center, radius: radius - 6);

    for (var i = 0; i < count; i++) {
      // Canvas: 0 = east, positive sweep = clockwise.
      // Segment i is centered at top (-pi/2) + i * sweep.
      final start = -math.pi / 2 - sweep / 2 + i * sweep;
      final mid = start + sweep / 2;

      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            radius,
            [colors[i].withValues(alpha: 0.85), colors[i]],
          ),
      );
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFFFE082),
      );
      final labelRadius = radius * 0.58;
      final labelCenter = Offset(
        center.dx + math.cos(mid) * labelRadius,
        center.dy + math.sin(mid) * labelRadius,
      );

      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icons[i].codePoint),
          style: TextStyle(
            fontSize: 22,
            fontFamily: icons[i].fontFamily,
            package: icons[i].fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      iconPainter.paint(
        canvas,
        labelCenter - Offset(iconPainter.width / 2, iconPainter.height + 10),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: wheelCategories[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 3,
      )..layout(maxWidth: radius * 0.42);
      tp.paint(canvas, labelCenter - Offset(tp.width / 2, -4));
    }

    canvas.drawCircle(
      center,
      radius * 0.22,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius * 0.22,
          const [Color(0xFFFFF3C4), Color(0xFFD4AF37)],
        ),
    );
    canvas.drawCircle(
      center,
      radius * 0.22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF8B6914),
    );

    final hub = TextPainter(
      text: const TextSpan(
        text: 'عجلة\nالمعرفة',
        style: TextStyle(
          color: Color(0xFF5C3B00),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: radius * 0.38);
    hub.paint(canvas, center - Offset(hub.width / 2, hub.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
