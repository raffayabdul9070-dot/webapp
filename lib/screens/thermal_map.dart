import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/heat_alert.dart';
import '../models/temperature_reading.dart';

class ThermalMap extends StatefulWidget {
  final TemperatureReading? reading;
  final HeatSeverity severity;
  final Color severityColor;
  final bool isPolling;
  const ThermalMap(
      {super.key,
      required this.reading,
      required this.severity,
      required this.severityColor,
      required this.isPolling});
  @override
  State<ThermalMap> createState() => _ThermalMapState();
}

class _ThermalMapState extends State<ThermalMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..repeat();
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: CustomPaint(
                painter: _MapPainter(
                    progress: _animation,
                    severityColor: widget.severityColor))),
        Positioned(
            top: 18,
            left: 18,
            child: _tag('OHIO / LOCALIZED GRID', const Color(0xFFE6B84A))),
        Positioned(
            top: 18,
            right: 18,
            child: _tag(widget.isPolling ? 'SCANNING...' : 'SCAN ACTIVE',
                const Color(0xFF28D7F2))),
        Positioned(
            left: 18,
            bottom: 18,
            child: _tag(
                widget.reading == null
                    ? 'AWAITING TELEMETRY'
                    : 'TARGET LOCK // ${widget.reading!.effectiveTempF.toStringAsFixed(1)}°F',
                widget.severityColor)),
      ]);
  Widget _tag(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: const Color(0xCC050A12),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1)));
}

class _MapPainter extends CustomPainter {
  final Animation<double> progress;
  final Color severityColor;
  _MapPainter({required this.progress, required this.severityColor})
      : super(repaint: progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .52, size.height * .52);
    final radius = math.min(size.width, size.height) * .36;
    final grid = Paint()
      ..color = const Color(0xFF28D7F2).withOpacity(.1)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 28)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (var y = 0.0; y <= size.height; y += 28)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    final region = Path()
      ..moveTo(center.dx - radius * .62, center.dy - radius * .72)
      ..lineTo(center.dx + radius * .18, center.dy - radius * .76)
      ..lineTo(center.dx + radius * .55, center.dy - radius * .42)
      ..lineTo(center.dx + radius * .48, center.dy + radius * .05)
      ..lineTo(center.dx + radius * .72, center.dy + radius * .48)
      ..lineTo(center.dx + radius * .18, center.dy + radius * .7)
      ..lineTo(center.dx - radius * .28, center.dy + radius * .5)
      ..lineTo(center.dx - radius * .7, center.dy + radius * .3)
      ..lineTo(center.dx - radius * .58, center.dy - radius * .18)
      ..close();
    canvas.drawPath(
        region, Paint()..color = const Color(0xFF113044).withOpacity(.48));
    canvas.drawPath(
        region,
        Paint()
          ..color = const Color(0xFF28D7F2).withOpacity(.48)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    for (final zone in [
      (Offset(-.25, -.25), .2, const Color(0xFFE6B84A)),
      (Offset(.28, .08), .24, const Color(0xFFFF8A3D)),
      (Offset(.05, .4), .16, const Color(0xFFFF4D5E)),
    ]) {
      final zoneCenter =
          center + Offset(zone.$1.dx * radius, zone.$1.dy * radius);
      canvas.drawCircle(
          zoneCenter,
          radius * zone.$2,
          Paint()
            ..shader = RadialGradient(colors: [
              zone.$3.withOpacity(.62),
              zone.$3.withOpacity(.04),
              Colors.transparent
            ]).createShader(
                Rect.fromCircle(center: zoneCenter, radius: radius * zone.$2)));
    }
    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF28D7F2).withOpacity(.32);
    for (var i = 1; i <= 4; i++)
      canvas.drawCircle(center, radius * i / 4, rings);
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), grid);
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), grid);
    for (final offset in [
      const Offset(-.25, -.16),
      const Offset(.28, .12),
      const Offset(-.05, .32),
      const Offset(.38, -.3)
    ]) {
      final point = center + Offset(offset.dx * radius, offset.dy * radius);
      canvas.drawCircle(
          point, radius * .12, Paint()..color = severityColor.withOpacity(.12));
      canvas.drawCircle(
          point, radius * .05, Paint()..color = severityColor.withOpacity(.32));
    }
    final angle = progress.value * math.pi * 2;
    final sweep = Paint()
      ..shader = SweepGradient(
          startAngle: angle - .65,
          endAngle: angle,
          colors: [
            Colors.transparent,
            const Color(0xFF28D7F2).withOpacity(.62)
          ]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), angle - .65,
        .65, true, sweep);
    final marker = Paint()
      ..color = const Color(0xFFE6B84A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final offset in [
      const Offset(-.62, -.35),
      const Offset(.58, -.1),
      const Offset(.2, .58)
    ]) {
      final point = center + Offset(offset.dx * radius, offset.dy * radius);
      canvas.drawCircle(point, 5, marker);
      canvas.drawLine(
          point - const Offset(9, 0), point + const Offset(9, 0), marker);
      canvas.drawLine(
          point - const Offset(0, 9), point + const Offset(0, 9), marker);
    }
    canvas.drawCircle(center, 7, Paint()..color = severityColor);
    canvas.drawCircle(
        center,
        15,
        Paint()
          ..color = severityColor.withOpacity(.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final label = TextPainter(
        text: const TextSpan(
            text: 'OHIO GRID',
            style: TextStyle(
                color: Color(0xFF28D7F2),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr)
      ..layout();
    label.paint(
        canvas, Offset(center.dx - radius * .52, center.dy + radius * .78));
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.severityColor != severityColor;
}
