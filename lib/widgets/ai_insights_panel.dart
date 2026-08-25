import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiInsightsPanel extends StatelessWidget {
  final String insightText;
  final bool isLoading;

  const AiInsightsPanel({
    super.key,
    required this.insightText,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12).withOpacity(0.8), // Obsidian
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLoading ? const Color(0xFFD4AF37).withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
          if (isLoading)
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 2,
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: const Color(0xFFD4AF37), // Gold
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'A.E.G.I.S. AI ANALYSIS',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    const Spacer(),
                    if (isLoading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insightText.isEmpty ? 'Scanning grid coordinates for heat anomalies...' : insightText,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
