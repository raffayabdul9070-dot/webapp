import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/heat_alert.dart';

class AlertHistoryCard extends StatelessWidget {
  final HeatAlert alert;

  const AlertHistoryCard({super.key, required this.alert});

  Color get _color {
    switch (alert.severity) {
      case HeatSeverity.normal:
        return const Color(0xFF38BDF8);
      case HeatSeverity.watch:
        return const Color(0xFFD4AF37); // Gold
      case HeatSeverity.warning:
        return const Color(0xFFF97316);
      case HeatSeverity.emergency:
        return const Color(0xFFFF2A2A); // Bright Red
    }
  }

  IconData get _icon {
    switch (alert.severity) {
      case HeatSeverity.normal:
        return Icons.check_circle_outline;
      case HeatSeverity.watch:
        return Icons.visibility_outlined;
      case HeatSeverity.warning:
        return Icons.warning_amber_rounded;
      case HeatSeverity.emergency:
        return Icons.emergency_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(alert.createdAt);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12), // Obsidian background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
        boxShadow: [
          // Neomorphic drop shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          // Subtle glow matching severity
          BoxShadow(
            color: _color.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glowing Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _color.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withOpacity(0.2),
                        blurRadius: 10,
                      )
                    ]
                  ),
                  child: Icon(_icon, color: _color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            alert.severity.label.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 1.2,
                              color: _color,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${alert.reading.locationName} · Grid ${alert.reading.gridId}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${alert.reading.effectiveTempF.toStringAsFixed(1)}°F Recorded',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white54,
                        ),
                      ),
                      if (alert.dispatchedToResponders || alert.dispatchedToResidents) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (alert.dispatchedToResponders)
                              _tag('RESPONDERS NOTIFIED', Icons.local_fire_department),
                            if (alert.dispatchedToResidents)
                              _tag('RESIDENTS NOTIFIED', Icons.people_alt_outlined),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.2),
            blurRadius: 5,
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
