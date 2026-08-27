import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _cyan = Color(0xFF28D7F2);
const _gold = Color(0xFFE6B84A);

class DashboardPanel extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  const DashboardPanel(
      {super.key,
      required this.child,
      this.accent = _cyan,
      this.padding = const EdgeInsets.all(14)});
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _PanelFramePainter(accent),
        child: Container(
            padding: padding,
            decoration: const BoxDecoration(color: Color(0xE608121D)),
            child: child),
      );
}

class DashboardLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const DashboardLabel(this.text, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: _gold),
        const SizedBox(width: 7),
        Text(text,
            style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white70)),
      ]);
}

class MiniLineChart extends StatelessWidget {
  final Color color;
  const MiniLineChart({super.key, this.color = _cyan});
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 54, child: CustomPaint(painter: _LinePainter(color)));
}

class MiniBars extends StatelessWidget {
  final Color color;
  const MiniBars({super.key, this.color = _gold});
  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 48, child: CustomPaint(painter: _BarsPainter(color)));
}

class MiniGauge extends StatelessWidget {
  final double value;
  final Color color;
  const MiniGauge({super.key, required this.value, this.color = _gold});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 58,
      height: 58,
      child: CustomPaint(painter: _GaugePainter(value.clamp(0, 1), color)));
}

class SignalBars extends StatelessWidget {
  final int active;
  final Color color;
  const SignalBars({super.key, required this.active, this.color = _cyan});
  @override
  Widget build(BuildContext context) => Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
          5,
          (index) => Container(
              width: 4,
              height: 7.0 + index * 3,
              margin: const EdgeInsets.only(left: 2),
              color: index < active ? color : Colors.white12)));
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, {super.key, this.color = _cyan});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          border: Border.all(color: color.withValues(alpha: .55))),
      child: Text(text,
          style: GoogleFonts.spaceMono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: .8)));
}

class _PanelFramePainter extends CustomPainter {
  final Color color;
  _PanelFramePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 10)
      ..lineTo(10, 0)
      ..lineTo(size.width - 10, 0)
      ..lineTo(size.width, 10)
      ..lineTo(size.width, size.height - 10)
      ..lineTo(size.width - 10, size.height)
      ..lineTo(10, size.height)
      ..lineTo(0, size.height - 10)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawLine(
        const Offset(0, 10),
        const Offset(0, 27),
        Paint()
          ..color = color
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _PanelFramePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LinePainter extends CustomPainter {
  final Color color;
  _LinePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    const values = [
      0.0,
      .42,
      .28,
      .6,
      .46,
      .72,
      .5,
      .85,
      .68,
      .62,
      .88,
      .77,
      1.0
    ];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
          size.width * i / (values.length - 1), size.height * (1 - values[i]));
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    canvas.drawCircle(
        Offset(size.width, size.height * .23), 3, Paint()..color = _gold);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BarsPainter extends CustomPainter {
  final Color color;
  _BarsPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    const values = [.35, .55, .42, .78, .66, .92, .7, .84, .58, .76];
    final paint = Paint()..color = color.withValues(alpha: .82);
    for (var i = 0; i < values.length; i++) {
      canvas.drawRect(
          Rect.fromLTWH(
              i * size.width / values.length + 2,
              size.height * (1 - values[i]),
              size.width / values.length - 4,
              size.height * values[i]),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter(this.value, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - 5);
    canvas.drawArc(
        rect,
        math.pi * .75,
        math.pi * 1.5,
        false,
        Paint()
          ..color = Colors.white12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    canvas.drawArc(
        rect,
        math.pi * .75,
        math.pi * 1.5 * value,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    final label = TextPainter(
        text: TextSpan(
            text: '${(value * 100).round()}',
            style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr)
      ..layout();
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
