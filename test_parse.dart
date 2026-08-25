import 'dart:convert';
import 'package:http/http.dart' as http;

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
}

void main() {
  final statusBodyStr = '''
  {"error":false,"status_code":200,"message":"Completed","data":{"activity_id":"7f798de0-63df-4fa1-a6b5-267354363437","status":"Completed","result":{"metadata":{"timezone":"GMT-6","timezone_offset_hours":-6,"time_range":{"start":"2026-08-25T05:55:00-06:00","end":"2026-08-25T05:55:00-06:00","interval":"1h","count":1},"timestamps":["2026-08-25T05:55:00-06:00"]},"locations":[{"lat":40.4173,"lon":-82.9071,"elevation":null,"temperature":90.0,"parameters":{"heat_index_celsius":[],"apparent_temperature_celsius":[],"relative_humidity_percent":[],"precipitation_mm":[],"cloud_cover_octas":[],"wet_bulb_temperature_celsius":[],"elevation_meters":[],"air_quality:idx":[],"air_quality_pm2p5:idx":[],"air_quality_pm10:idx":[],"air_quality_no2:idx":[],"aqi_us_co":[],"air_quality_o3:idx":[],"air_quality_so2:idx":[],"methane_ppb":[],"co2_ppm":[]},"solar_irradiance":{"clear_sky":{"ghi":88.76,"dni":233.52,"dhi":44.28}}}]}}}
  ''';

  final statusBody = jsonDecode(statusBodyStr);
  final statusStr = (statusBody['status'] ?? '').toString().toLowerCase();
  print('statusStr (from top level): "$statusStr"');
  
  final dataStatusStr = (statusBody['data']?['status'] ?? '').toString().toLowerCase();
  print('dataStatusStr: "$dataStatusStr"');

  final dataBlock = statusBody['data'] ?? statusBody;
  Map<String, dynamic> data = {};
  
  if (dataBlock['result'] != null && 
      dataBlock['result']['locations'] != null && 
      (dataBlock['result']['locations'] as List).isNotEmpty) {
    data = Map<String, dynamic>.from(dataBlock['result']['locations'][0]);
    
    if (data['parameters'] != null) {
      final params = data['parameters'] as Map<String, dynamic>;
      if (params['temperature_celsius'] != null && (params['temperature_celsius'] as List).isNotEmpty) {
        data['temperature_celsius'] = params['temperature_celsius'][0];
      }
      if (params['heat_index_celsius'] != null && (params['heat_index_celsius'] as List).isNotEmpty) {
        data['heat_index_celsius'] = params['heat_index_celsius'][0];
      }
      if (params['relative_humidity_percent'] != null && (params['relative_humidity_percent'] as List).isNotEmpty) {
        data['relative_humidity_percent'] = params['relative_humidity_percent'][0];
      }
    }
  } else {
    data = Map<String, dynamic>.from(dataBlock);
  }
  
  double toF(num c) => (c * 9 / 5) + 32;
  if (data['temperature_celsius'] != null) {
    data['temperature_f'] = toF(data['temperature_celsius']);
  }
  if (data['heat_index_celsius'] != null) {
    data['heat_index_f'] = toF(data['heat_index_celsius']);
  }
  
  print('Data map passed to fromJson: $data');
  final reading = TemperatureReading.fromJson(data);
  print('Reading: ${reading.toJson()}');
}
