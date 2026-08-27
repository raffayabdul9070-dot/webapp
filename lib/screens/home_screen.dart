import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_config.dart';
import '../models/heat_alert.dart';
import '../models/temperature_reading.dart';
import '../services/heat_monitor_service.dart';
import '../services/ai_insights_service.dart';
import '../widgets/alert_history_card.dart';
import '../widgets/temperature_trend_chart.dart';
import '../widgets/ai_insights_panel.dart';
import '../widgets/dashboard_visuals.dart';
import 'thermal_map.dart';

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
          _aiInsight =
              "AI Analysis: Grid monitoring active. Current thermal readings are within normal operational limits. Responders on standby.";
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
      case HeatSeverity.normal:
        return const Color(0xFF38BDF8);
      case HeatSeverity.watch:
        return const Color(0xFFD4AF37);
      case HeatSeverity.warning:
        return const Color(0xFFF97316);
      case HeatSeverity.emergency:
        return const Color(0xFFFF2A2A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildDashboard();
    /*
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFD4AF37)),
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
                        const Icon(Icons.location_on,
                            color: Color(0xFFD4AF37), size: 16),
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
                        const Icon(Icons.history,
                            color: Color(0xFFD4AF37), size: 20),
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
                            Icon(Icons.shield_outlined,
                                size: 48, color: Colors.white.withOpacity(0.1)),
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
                    ..._monitor.alertHistory
                        .map((a) => AlertHistoryCard(alert: a)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    ); */
  }

  Widget _buildDashboard() {
    final reading = _latestReading;
    final panel = (Widget child, {Color? accent}) => DashboardPanel(
          child: child,
          accent: accent ?? const Color(0xFF28D7F2),
        );
    TextStyle mono(
            {double size = 12,
            Color color = Colors.white,
            FontWeight weight = FontWeight.w400,
            double spacing = 0}) =>
        GoogleFonts.spaceMono(
            fontSize: size,
            color: color,
            fontWeight: weight,
            letterSpacing: spacing);
    Widget label(String text, IconData icon) => Row(children: [
          Icon(icon, size: 15, color: const Color(0xFFE6B84A)),
          const SizedBox(width: 7),
          Text(text,
              style: mono(
                  size: 11,
                  color: Colors.white70,
                  weight: FontWeight.w800,
                  spacing: 1.6))
        ]);
    Widget railMetric(String title, String value, Color color) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: mono(size: 9, color: Colors.white54, spacing: 1)),
          const SizedBox(height: 5),
          Text(value,
              style: mono(size: 25, color: color, weight: FontWeight.w700))
        ]);
    Widget signal(String title, double value, String display, Color color) =>
        Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(title,
                    style: mono(size: 9, color: Colors.white60, spacing: 1)),
                Text(display,
                    style:
                        mono(size: 10, color: color, weight: FontWeight.w700))
              ]),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  color: color)
            ]));
    Widget status(String title, String value, bool good) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: good ? const Color(0xFF28D7F2) : _severityColor,
                  shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(
              child: Text(title, style: mono(size: 9, color: Colors.white60))),
          Text(value,
              style: mono(
                  size: 9,
                  color: good ? const Color(0xFF28D7F2) : _severityColor,
                  weight: FontWeight.w700))
        ]));
    Widget rightRail() =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label('LIVE CONDITIONS', Icons.wb_sunny_outlined),
          const SizedBox(height: 8),
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_severity.label.toUpperCase(),
                  style: mono(
                      size: 10,
                      color: _severityColor,
                      weight: FontWeight.w800,
                      spacing: 1)),
              Text(
                  reading == null
                      ? 'NO DATA'
                      : '${reading.effectiveTempF.toStringAsFixed(1)}°F',
                  style: mono(
                      size: 19, color: _severityColor, weight: FontWeight.w700))
            ]),
            const SizedBox(height: 10),
            Text(reading?.locationName ?? AppConfig.targetLocationName,
                style: mono(size: 19, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                reading == null
                    ? 'Connecting to localized feed...'
                    : _severity.description,
                style: mono(size: 11, color: Colors.white60)),
            const SizedBox(height: 12),
            Text(
                'HUMIDITY  ${reading?.humidityPct?.toStringAsFixed(0) ?? '--'}%',
                style: mono(size: 10, color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
                'HEAT INDEX  ${reading?.heatIndexF?.toStringAsFixed(1) ?? '--'}°F',
                style: mono(size: 10, color: Colors.white70))
          ])),
          const SizedBox(height: 12),
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SYSTEM STATUS',
                style: mono(
                    size: 10,
                    color: Colors.white60,
                    weight: FontWeight.w800,
                    spacing: 1.4)),
            const SizedBox(height: 14),
            status('MONITORING LOOP', _error == null ? 'ACTIVE' : 'DEGRADED',
                _error == null),
            status('LOCAL ALERTS', 'READY', true),
            status('AI ANALYSIS', _isLoadingAi ? 'PROCESSING' : 'STANDBY',
                !_isLoadingAi)
          ])),
          const SizedBox(height: 12),
          AiInsightsPanel(insightText: _aiInsight, isLoading: _isLoadingAi),
          const SizedBox(height: 12),
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('THRESHOLDS',
                style: mono(
                    size: 10,
                    color: Colors.white60,
                    weight: FontWeight.w800,
                    spacing: 1.4)),
            const SizedBox(height: 12),
            Text(
                'WATCH       ${AppConfig.watchThresholdF.toStringAsFixed(0)}°F',
                style: mono(size: 10, color: const Color(0xFFE6B84A))),
            const SizedBox(height: 8),
            Text(
                'WARNING   ${AppConfig.warningThresholdF.toStringAsFixed(0)}°F',
                style: mono(size: 10, color: const Color(0xFFFF8A3D))),
            const SizedBox(height: 8),
            Text(
                'EMERGENCY ${AppConfig.emergencyThresholdF.toStringAsFixed(0)}°F',
                style: mono(size: 10, color: const Color(0xFFFF4D5E)))
          ])),
          const SizedBox(height: 12),
          label('ALERT QUEUE', Icons.notifications_none),
          const SizedBox(height: 6),
          if (_monitor.alertHistory.isEmpty)
            panel(Text('NO ACTIVE ALERTS',
                style: mono(
                    size: 10,
                    color: const Color(0xFF28D7F2),
                    weight: FontWeight.w700,
                    spacing: 1)))
          else
            ..._monitor.alertHistory
                .take(3)
                .map((alert) => AlertHistoryCard(alert: alert))
        ]);
    Widget leftRail() =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label('TELEMETRY', Icons.bar_chart_rounded),
          const SizedBox(height: 8),
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            railMetric(
                'EFFECTIVE TEMP',
                reading == null
                    ? '--'
                    : '${reading.effectiveTempF.toStringAsFixed(1)}°F',
                _severityColor),
            const Divider(color: Colors.white12, height: 24),
            Text(
                'AIR TEMP  ${reading?.temperatureF.toStringAsFixed(1) ?? '--'}°',
                style: mono(size: 10, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('GRID ID   ${reading?.gridId ?? '--'}',
                style: mono(size: 10, color: Colors.white70))
          ])),
          const SizedBox(height: 12),
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SIGNAL MONITORS',
                style: mono(
                    size: 10,
                    color: Colors.white60,
                    weight: FontWeight.w800,
                    spacing: 1.3)),
            const SizedBox(height: 14),
            signal(
                'HUMIDITY',
                (reading?.humidityPct ?? 0) / 100,
                '${reading?.humidityPct?.toStringAsFixed(0) ?? '--'}%',
                const Color(0xFF28D7F2)),
            signal(
                'HEAT INDEX',
                ((reading?.effectiveTempF ?? 0) / 120),
                '${reading?.heatIndexF?.toStringAsFixed(1) ?? '--'}°',
                const Color(0xFFFF8A3D)),
            signal('UV-LIKE', .78, '10 SIM', const Color(0xFFE6B84A))
          ])),
          const SizedBox(height: 12),
          panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LOAD PROFILE / SIMULATED',
                style: mono(size: 9, color: Colors.white60, spacing: 1)),
            const SizedBox(height: 8),
            const MiniBars(color: Color(0xFFFF8A3D)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('0600', style: mono(size: 8, color: Colors.white38)),
              Text('1200', style: mono(size: 8, color: Colors.white38)),
              Text('1800', style: mono(size: 8, color: Colors.white38)),
            ])
          ])),
          const SizedBox(height: 12),
          if (_monitor.readingHistory.isNotEmpty)
            TemperatureTrendChart(history: _monitor.readingHistory)
        ]);
    Widget center() =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          label('THERMAL MAP', Icons.radar),
          const SizedBox(height: 8),
          SizedBox(
              height: 520,
              child: panel(
                  ThermalMap(
                      reading: reading,
                      severity: _severity,
                      severityColor: _severityColor,
                      isPolling: _checking),
                  accent: _severityColor)),
          const SizedBox(height: 12),
          panel(Row(children: [
            const Icon(Icons.location_on_outlined,
                color: Color(0xFFE6B84A), size: 17),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    '${AppConfig.targetLocationName.toUpperCase()} GRID / ${reading?.gridId ?? 'AWAITING SIGNAL'}',
                    style:
                        mono(size: 10, weight: FontWeight.w700, spacing: 1))),
            StatusChip(_checking ? 'SCANNING' : 'CHECK NOW',
                color: const Color(0xFFE6B84A))
          ])),
          const SizedBox(height: 10),
          panel(Row(children: [
            Text('TIMELINE',
                style: mono(
                    size: 9,
                    color: Colors.white60,
                    weight: FontWeight.w700,
                    spacing: 1.2)),
            const SizedBox(width: 10),
            const Expanded(child: MiniLineChart()),
            const SizedBox(width: 10),
            Text('12:00:00Z', style: mono(size: 8, color: Colors.white54)),
          ])),
          const SizedBox(height: 10),
          panel(Row(children: [
            const MiniGauge(value: .72, color: Color(0xFFFF8A3D)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('SENSOR ARRAY',
                      style: mono(
                          size: 10,
                          color: Colors.white70,
                          weight: FontWeight.w800,
                          spacing: 1.3)),
                  const SizedBox(height: 6),
                  Text('MULTI-POINT THERMAL FIELD',
                      style: mono(size: 8, color: Colors.white54)),
                  const SizedBox(height: 7),
                  Row(children: [
                    const SignalBars(active: 4),
                    const SizedBox(width: 8),
                    Text('04 / 05 ONLINE',
                        style: mono(size: 8, color: const Color(0xFF28D7F2)))
                  ])
                ])),
          ])),
          const SizedBox(height: 10),
          panel(
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            StatusChip(_severity.label.toUpperCase(), color: _severityColor),
            const StatusChip('SIMULATED', color: Color(0xFFE6B84A)),
            Text('NORMAL  /  WATCH  /  WARNING',
                style: mono(size: 7, color: Colors.white54, spacing: .4)),
          ]))
        ]);
    return Scaffold(
        backgroundColor: const Color(0xFF050A12),
        appBar: AppBar(
            backgroundColor: const Color(0xFF050A12),
            title: Text('A.E.G.I.S.',
                style: mono(size: 20, weight: FontWeight.w800, spacing: 3)),
            actions: [
              Text('LIVE FEED',
                  style: mono(size: 9, color: Colors.white60, spacing: 1)),
              IconButton(
                  tooltip: 'Check now',
                  onPressed: _checking ? null : _checkNow,
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFE6B84A)))
                      : const Icon(Icons.sync, color: Color(0xFFE6B84A)))
            ]),
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: _checkNow,
                color: const Color(0xFF28D7F2),
                child: LayoutBuilder(builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1100;
                  final content = wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              SizedBox(width: 270, child: leftRail()),
                              const SizedBox(width: 14),
                              Expanded(child: center()),
                              const SizedBox(width: 14),
                              SizedBox(width: 310, child: rightRail())
                            ])
                      : Column(children: [center(), leftRail(), rightRail()]);
                  return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      child: content);
                }))));
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
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: const Color(0xFFD4AF37)),
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
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Colors.white.withOpacity(0.5)),
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
          item('Emergency', AppConfig.emergencyThresholdF,
              const Color(0xFFFF2A2A)),
        ],
      ),
    );
  }
}
