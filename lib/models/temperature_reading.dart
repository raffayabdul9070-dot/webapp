import 'dart:convert';

/// A single point-in-time reading from the FortyGuard temperature feed
/// for one localized grid cell.
class TemperatureReading {
  final String gridId;
  final String locationName;
  final double latitude;
  final double longitude;
  final double temperatureF;
  final double? heatIndexF;
  final double? humidityPct;
  final DateTime timestamp;

  const TemperatureReading({
    required this.gridId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.temperatureF,
    this.heatIndexF,
    this.humidityPct,
    required this.timestamp,
  });

  /// Effective temperature used for threshold checks: heat index if
  /// available (accounts for humidity), otherwise raw air temperature.
  double get effectiveTempF => heatIndexF ?? temperatureF;

  /// Parses a FortyGuard API JSON payload.
  ///
  /// TODO: confirm real field names against FortyGuard's docs. This parser
  /// is defensive — it tries several plausible key names so a real payload
  /// has a good chance of working without edits.
  factory TemperatureReading.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v, [double fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    dynamic _pick(Map<String, dynamic> j, List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k];
      }
      return null;
    }

    final tempRaw = _pick(json, ['temperatureF', 'temperature_f', 'temp_f', 'temperature']);
    final heatIdxRaw = _pick(json, ['heatIndexF', 'heat_index_f', 'heatIndex']);
    final humidityRaw = _pick(json, ['humidityPct', 'humidity', 'relative_humidity']);
    final latRaw = _pick(json, ['latitude', 'lat']);
    final lonRaw = _pick(json, ['longitude', 'lon', 'lng']);
    final gridRaw = _pick(json, ['gridId', 'grid_id', 'zoneId', 'id']);
    final nameRaw = _pick(json, ['locationName', 'location_name', 'name', 'zone']);
    final tsRaw = _pick(json, ['timestamp', 'observed_at', 'time']);

    return TemperatureReading(
      gridId: (gridRaw ?? 'unknown-grid').toString(),
      locationName: (nameRaw ?? 'Unknown').toString(),
      latitude: _num(latRaw),
      longitude: _num(lonRaw),
      temperatureF: _num(tempRaw),
      heatIndexF: heatIdxRaw == null ? null : _num(heatIdxRaw),
      humidityPct: humidityRaw == null ? null : _num(humidityRaw),
      timestamp: tsRaw != null
          ? (DateTime.tryParse(tsRaw.toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'gridId': gridId,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'temperatureF': temperatureF,
        'heatIndexF': heatIndexF,
        'humidityPct': humidityPct,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() => jsonEncode(toJson());
}
