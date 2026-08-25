import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_config.dart';
import '../models/heat_alert.dart';
import '../models/temperature_reading.dart';
import '../services/heat_monitor_service.dart';
import '../services/ai_insights_service.dart';
import '../widgets/alert_history_card.dart';
import '../widgets/temperature_gauge.dart';
import '../widgets/temperature_trend_chart.dart';
import '../widgets/ai_insights_panel.dart';
import '../widgets/metrics_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HeatMonitorService _monitor = HeatMonitorService();
  final AiInsightsService _aiService = AiInsightsService();

  TemperatureReading? _latestReading;
  HeatSeverity _severity = HeatSeverity.normal;
  Object? _error;
  bool _checking = false;
  
  String _aiInsight = '';
  bool _isLoadingAi = false;

  @override
  void initState() {
    super.initState();
    _monitor.readings.listen((r) {
      setState(() {
        _latestReading = r;
        _severity = _monitor.currentSeverity;
        _error = null;
        _checking = false;
      });
    }, onError: (e) {
      setState(() {
        _error = e;
        _checking = false;
      });
    });
    
    _monitor.alerts.listen((alert) async {
      setState(() {
        _isLoadingAi = true;
      });
      final insight = await _aiService.generateInsight(alert);
      if (mounted) {
        setState(() {
          _aiInsight = insight;
          _isLoadingAi = false;
        });
      }
    });
    
    _monitor.start();

    // After 2.5 seconds, if no alert has fired, set a baseline AI reading.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _aiInsight.isEmpty && !_isLoadingAi) {
        setState(() {
          _aiInsight = "AI Analysis: Grid monitoring active. Current thermal readings are within normal operational limits. Responders on standby.";
        });
      }
    });
  }

  @override
  void dispose() {
    _monitor.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    await _monitor.pollOnce();
  }

  Color get _severityColor {
    switch (_severity) {
      case HeatSeverity.normal: return const Color(0xFF38BDF8);
      case HeatSeverity.watch: return const Color(0xFFD4AF37);
      case HeatSeverity.warning: return const Color(0xFFF97316);
      case HeatSeverity.emergency: return const Color(0xFFFF2A2A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF070709), // Deep Obsidian
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'A.E.G.I.S.', // Luxury codename
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Check now',
            icon: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                  )
                : const Icon(Icons.sync, color: Color(0xFFD4AF37)),
            onPressed: _checking ? null : _checkNow,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dynamic 3D Radial Lighting
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            top: -200,
            left: MediaQuery.of(context).size.width / 2 - 300,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _severityColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _checkNow,
              color: const Color(0xFFD4AF37),
              backgroundColor: const Color(0xFF0F0F12),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (AppConfig.demoMode) 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _demoModeBanner(),
                    ),
                  
                  const SizedBox(height: 10),
                  
                  // Location Header
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          AppConfig.targetLocationName.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Main 3D Gauge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TemperatureGauge(
                        temperatureF: _latestReading?.effectiveTempF,
                        severity: _severity,
                        isPolling: _checking,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Metrics Grid
                  if (_latestReading != null)
                    MetricsGrid(reading: _latestReading!),
                    
                  // Trend Chart
                  if (_monitor.readingHistory.isNotEmpty)
                    TemperatureTrendChart(history: _monitor.readingHistory),

                  // Groq AI Panel
                  AiInsightsPanel(
                    insightText: _aiInsight,
                    isLoading: _isLoadingAi,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _thresholdLegend(),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Alert History Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: Color(0xFFD4AF37), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SYSTEM LOG',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_monitor.alertHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.shield_outlined, size: 48, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(
                              'ALL SYSTEMS NOMINAL',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._monitor.alertHistory.map((a) => AlertHistoryCard(alert: a)),
                    
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoModeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: Color(0xFFD4AF37)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'DEMO MODE ENABLED',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: const Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thresholdLegend() {
    Widget item(String label, double val, Color c) => Expanded(
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: c.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 2),
              Text(
                '${val.toStringAsFixed(0)}°',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          item('Watch', AppConfig.watchThresholdF, const Color(0xFFD4AF37)),
          item('Warning', AppConfig.warningThresholdF, const Color(0xFFF97316)),
          item('Emergency', AppConfig.emergencyThresholdF, const Color(0xFFFF2A2A)),
        ],
      ),
    );
  }
}
