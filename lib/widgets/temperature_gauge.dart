import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/heat_alert.dart';

class TemperatureGauge extends StatefulWidget {
  final double? temperatureF;
  final HeatSeverity severity;
  final bool isPolling;

  const TemperatureGauge({
    super.key,
    required this.temperatureF,
    required this.severity,
    this.isPolling = false,
  });

  @override
  State<TemperatureGauge> createState() => _TemperatureGaugeState();
}

class _TemperatureGaugeState extends State<TemperatureGauge>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    if (widget.isPolling) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TemperatureGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPolling && !oldWidget.isPolling) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPolling && oldWidget.isPolling) {
      _pulseController.animateTo(0,
          duration: const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.severity) {
      case HeatSeverity.normal:
        return const Color(0xFF38BDF8); // Tailwind light blue
      case HeatSeverity.watch:
        return const Color(0xFFD4AF37); // Gold
      case HeatSeverity.warning:
        return const Color(0xFFF97316); // Tailwind orange
      case HeatSeverity.emergency:
        return const Color(0xFFFF2A2A); // Bright Red
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _spinController]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPolling ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: 280,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _color.withOpacity(widget.isPolling ? 0.6 : 0.3),
                    blurRadius: widget.isPolling ? 80 : 50,
                    spreadRadius: widget.isPolling ? 5 : 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(10, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(-10, -10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(280),
                    painter: _GaugeBezelPainter(
                      color: _color,
                      rotation: _spinController.value * math.pi * 2,
                      isPolling: widget.isPolling,
                    ),
                  ),
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                      child: Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F0F12).withOpacity(0.7),
                          border: Border.all(
                            color: _color.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Inner 3D ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _color.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: -5,
                            offset: const Offset(0, 5),
                          )
                        ]),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.temperatureF == null
                            ? '--'
                            : '${widget.temperatureF!.toStringAsFixed(1)}°',
                        style: GoogleFonts.outfit(
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -2,
                          shadows: [
                            Shadow(
                              color: _color.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                            ),
                            const Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            color: _color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: _color.withOpacity(0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _color.withOpacity(0.3),
                                blurRadius: 10,
                              )
                            ]),
                        child: Text(
                          widget.severity.label.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: _color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugeBezelPainter extends CustomPainter {
  final Color color;
  final double rotation;
  final bool isPolling;

  const _GaugeBezelPainter({
    required this.color,
    required this.rotation,
    required this.isPolling,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withOpacity(0.38);

    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 8), width: 236, height: 48),
      glowPaint..color = color.withOpacity(0.18),
    );
    canvas.drawOval(
      Rect.fromCircle(center: center, radius: radius - 8),
      glowPaint..color = Colors.white.withOpacity(0.14),
    );

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (var index = 0; index < 32; index++) {
      final angle = rotation + index * math.pi * 2 / 32;
      final isMajor = index % 4 == 0;
      final inner = radius - (isMajor ? 23 : 18);
      final outer = radius - 10;
      tickPaint.color = color.withOpacity(isMajor ? 0.8 : 0.28);
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * inner,
            center.dy + math.sin(angle) * inner),
        Offset(center.dx + math.cos(angle) * outer,
            center.dy + math.sin(angle) * outer),
        tickPaint,
      );
    }

    final scanPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = color.withOpacity(isPolling ? 0.95 : 0.55);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      rotation - 0.55,
      0.24,
      false,
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugeBezelPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.rotation != rotation ||
      oldDelegate.isPolling != isPolling;
}
