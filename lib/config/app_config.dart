import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central configuration for the Heatwave Alert System.
///
/// IMPORTANT (read this before your demo):
/// - Put your real FortyGuard API key in [fortyGuardApiKey] below, or better,
///   pass it in with --dart-define=FORTYGUARD_API_KEY=xxxx so it never gets
///   committed to source control.
/// - [fortyGuardBaseUrl] and the JSON field names used in
///   `FortyGuardService` are my best-effort scaffold based on typical
///   climate-data REST APIs. I do not have FortyGuard's actual API
///   reference in front of me, so double check the real endpoint path,
///   auth header name, and response field names against FortyGuard's docs
///   or Postman collection, and adjust `FortyGuardService` accordingly.
///   Everything is isolated in one file (`fortyguard_service.dart`) to make
///   that a five-minute fix.
class AppConfig {
  AppConfig._();
  static String get fortyGuardApiKey => dotenv.env['FORTYGUARD_API_KEY'] ?? '';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  /// Base URL for FortyGuard's live temperature feed.
  /// Confirm this against the FortyGuard developer docs — placeholder host
  /// shown here follows their public dashboard naming.
  static const String fortyGuardBaseUrl = String.fromEnvironment(
    'FORTYGUARD_BASE_URL',
    defaultValue: 'https://api.fortyguard.com/v1',
  );

  /// The location selected on your FortyGuard dashboard.
  /// Ohio, statewide grid centroid used as the default monitoring point.
  /// Swap in a specific city/neighborhood grid ID once you know FortyGuard's
  /// grid identifier scheme (they may use lat/lon, geohash, or a named
  /// zone id — see the TODO in fortyguard_service.dart).
  static const String targetLocationName = 'Ohio';
  static const double targetLatitude = 40.4173;
  static const double targetLongitude = -82.9071;

  /// How often to poll the feed for new readings.
  static const Duration pollInterval = Duration(minutes: 5);

  /// Heat risk thresholds in Fahrenheit. Tune these to match NWS HeatRisk /
  /// local public-health guidance for your hackathon demo narrative.
  static const double watchThresholdF = 95.0; // Elevated risk
  static const double warningThresholdF = 103.0; // Dangerous
  static const double emergencyThresholdF = 110.0; // Extreme / life-threatening

  /// Demo mode: when true, and no real API key is set, the app uses a
  /// simulated data generator instead of calling the network. This lets you
  /// demo the full alert pipeline offline during judging without depending
  /// on live network access.
  static bool get demoMode =>
      fortyGuardApiKey == 'PASTE_YOUR_FORTYGUARD_API_KEY_HERE';
}
