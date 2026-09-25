import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Three-second, skippable brand introduction shown after the native splash.
class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  Timer? _autoExitTimer;
  Timer? _exitTimer;
  bool _visible = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _autoExitTimer = Timer(const Duration(milliseconds: 2300), _leave);
  }

  void _leave() {
    if (!mounted || !_visible) return;
    _autoExitTimer?.cancel();
    setState(() => _visible = false);
    _exitTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _finished = true);
    });
  }

  void _skip() {
    if (!_finished) _leave();
  }

  @override
  void dispose() {
    _autoExitTimer?.cancel();
    _exitTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_finished)
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: Duration(milliseconds: _visible ? 0 : 700),
            curve: Curves.easeInOutCubic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: ColoredBox(
                color: const Color(0xFFF4F0E6),
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => CustomPaint(
                    painter: _SourceParticlePainter(_motion.value),
                    child: child,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/branding/miyuanfang_icon_master.png',
                          width: 156,
                          height: 156,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          '覓源方',
                          style: TextStyle(
                            color: Color(0xFF0E5A56),
                            fontSize: 42,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 7,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '循经典之源，索辨证之方',
                          style: TextStyle(
                            color: Color(0xFF263B59),
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 72),
                        const Text(
                          '轻触任意位置进入',
                          style: TextStyle(
                            color: Color(0x66818D89),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SourceParticlePainter extends CustomPainter {
  const _SourceParticlePainter(this.progress);

  final double progress;

  static const _points = <Offset>[
    Offset(.10, .18),
    Offset(.22, .30),
    Offset(.82, .20),
    Offset(.72, .33),
    Offset(.14, .64),
    Offset(.88, .61),
    Offset(.25, .78),
    Offset(.77, .82),
    Offset(.39, .13),
    Offset(.62, .72),
    Offset(.92, .39),
    Offset(.07, .43),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final teal = Paint()..color = const Color(0xFF0E5A56);
    final gold = Paint()..color = const Color(0xFFB58A45);
    for (var i = 0; i < _points.length; i++) {
      final phase = progress * math.pi * 2 + i * .73;
      final base = _points[i];
      final center = Offset(
        base.dx * size.width + math.sin(phase) * 8,
        base.dy * size.height + math.cos(phase * .8) * 12,
      );
      final pulse = .18 + (math.sin(phase) + 1) * .10;
      final paint = i % 4 == 0 ? gold : teal;
      paint.color = paint.color.withValues(alpha: pulse);
      canvas.drawCircle(center, i % 3 == 0 ? 2.4 : 1.6, paint);
    }

    final ripple = Paint()
      ..color = const Color(0xFF0E5A56).withValues(alpha: .06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final radius = size.width * (.12 + progress * .34);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .76),
        width: radius * 2,
        height: radius * .45,
      ),
      ripple,
    );
  }

  @override
  bool shouldRepaint(covariant _SourceParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
