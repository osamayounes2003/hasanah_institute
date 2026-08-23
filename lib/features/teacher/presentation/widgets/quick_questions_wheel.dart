import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class QuickQuestionsWheel extends StatefulWidget {
  const QuickQuestionsWheel({
    required this.onBeforeSpin,
    required this.onSpinComplete,
    this.enabled = true,
    super.key,
  });

  /// Return false to cancel the spin.
  final bool Function() onBeforeSpin;
  final Future<void> Function() onSpinComplete;
  final bool enabled;

  @override
  State<QuickQuestionsWheel> createState() => _QuickQuestionsWheelState();
}

class _QuickQuestionsWheelState extends State<QuickQuestionsWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotation;
  bool _spinning = false;
  double _turns = 0;

  static const _spinDuration = Duration(milliseconds: 1600);
  static const _segmentCount = 6;
  static const _colors = [
    Color(0xFF0F766E),
    Color(0xFFD4AF37),
    Color(0xFF0369A1),
    Color(0xFF7C3AED),
    Color(0xFFBE123C),
    Color(0xFFB45309),
  ];

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

  Future<void> _spin() async {
    if (_spinning || !widget.enabled) return;
    if (!widget.onBeforeSpin()) return;
    setState(() => _spinning = true);

    final random = math.Random();
    final extraTurns = 3 + random.nextInt(2);
    final begin = _turns;
    final end = begin + extraTurns + random.nextDouble();

    _rotation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.reset();
    await _controller.forward();
    _turns = end;
    _rotation = AlwaysStoppedAnimation(_turns);
    if (!mounted) return;
    setState(() => _spinning = false);
    await widget.onSpinComplete();
  }

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.sizeOf(context).width - 32, 340.0);
    final wheelSize = size * 0.9;

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
                        painter: const _QuickWheelPainter(),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 0,
                    child: CustomPaint(
                      size: Size(36, 40),
                      painter: _QuickPointerPainter(),
                    ),
                  ),
                ],
              ),
            ),
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
                : const Icon(Icons.flash_on_outlined),
            label: Text(
              _spinning ? 'تدور العجلة...' : 'تدوير الأسئلة السريعة',
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPointerPainter extends CustomPainter {
  const _QuickPointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Offset(size.width / 2, size.height);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(0, 8)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, 8)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFD4AF37));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF5C3B00),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickWheelPainter extends CustomPainter {
  const _QuickWheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const count = _QuickQuestionsWheelState._segmentCount;
    final sweep = 2 * math.pi / count;
    final rect = Rect.fromCircle(center: center, radius: radius - 6);

    for (var i = 0; i < count; i++) {
      final start = -math.pi / 2 - sweep / 2 + i * sweep;
      final color = _QuickQuestionsWheelState._colors[i];
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            radius,
            [color.withValues(alpha: 0.85), color],
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

    final hub = TextPainter(
      text: const TextSpan(
        text: 'أسئلة\nسريعة',
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
