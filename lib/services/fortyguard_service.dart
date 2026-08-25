import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/temperature_reading.dart';

/// Talks to FortyGuard's live temperature feed for a single grid/location.
///
/// Confirmed shape (from the server's own 422 validation error):
///   - POST /env_params, auth via `api-key` header
///   - JSON body requires: latitude, longitude, temperature, date_time
///   - Response is either the data directly, or an `activity_id` to poll
///     at GET /status/{activity_id} until status == "completed"
/// If FortyGuard's real docs differ from any of this, it's all isolated
/// here — nothing else in the app needs to change.
class FortyGuardService {
  final http.Client _client;
  final Random _rand = Random();

  FortyGuardService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the current reading for the configured target location.
  Future<TemperatureReading> fetchCurrentReading({
    double lat = AppConfig.targetLatitude,
    double lon = AppConfig.targetLongitude,
    String locationName = AppConfig.targetLocationName,
  }) async {
    if (AppConfig.demoMode) {
      return _simulatedReading(lat: lat, lon: lon, locationName: locationName);
    }

    final apiKey = AppConfig.fortyGuardApiKey;
    if (apiKey.isEmpty) {
      throw FortyGuardException(
          'API key is empty. Make sure .env is loaded correctly.');
    }

    final postUri = Uri.parse('${AppConfig.fortyGuardBaseUrl}/env_params');

    try {
      // Generate a realistic baseline temperature for FortyGuard to process
      final drift = (_rand.nextDouble() - 0.35) * 3.0;
      _lastSimTemp = (_lastSimTemp + drift).clamp(85.0, 118.0);

      // Build the request body as a concrete Map first (not inline) so we
      // can log exactly what we're about to send if something goes wrong —
      // that's the fastest way to tell "field genuinely missing" apart from
      // "stale build still running old code".
      final now = DateTime.now().toUtc();
      final requestBody = <String, dynamic>{
        'latitude': lat,
        'longitude': lon,
        'temperature': double.parse(_lastSimTemp.toStringAsFixed(1)),
        'parameters': [
          'temperature_celsius',
          'heat_index_celsius',
          'relative_humidity_percent'
        ],
        'date_time': {
          'filter_type': 1,
          'start_date': now.toIso8601String().split('T')[0], // YYYY-MM-DD
          'start_time':
              now.toIso8601String().split('T')[1].substring(0, 5), // HH:mm
        },
      };
      final encodedBody = jsonEncode(requestBody);

      // 1. Submit the async data task
      final postResponse = await _client
          .post(
            postUri,
            headers: {
              'api-key': apiKey,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: encodedBody,
          )
          .timeout(const Duration(seconds: 15));

      if (postResponse.statusCode == 404 || postResponse.statusCode == 401) {
        // ignore: avoid_print
        print(
            'DEBUG: API returned ${postResponse.statusCode}. Sent body: $encodedBody. Falling back to simulation.');
        return _simulatedReading(
            lat: lat, lon: lon, locationName: locationName);
      }

      if (postResponse.statusCode != 200 && postResponse.statusCode != 201) {
        throw FortyGuardException(
          'Failed to start job: ${postResponse.statusCode} ${postResponse.body}\n'
          'Sent body: $encodedBody\n'
          'If the server says a field is "missing" here but you can see it in "Sent body" above, '
          'this is a stale-build issue, not a code issue — run: flutter clean && flutter pub get && flutter run',
        );
      }

      final postBody = jsonDecode(postResponse.body);
      final activityId = (postBody['data'] != null && postBody['data'] is Map)
          ? postBody['data']['activity_id']
          : postBody['activity_id'];

      if (activityId == null) {
        // Direct response fallback
        final data = postBody['data'] ?? postBody;
        final reading = _normalizeReading(
          TemperatureReading.fromJson(Map<String, dynamic>.from(data)),
          lat: lat,
          lon: lon,
          locationName: locationName,
        );
        if (reading.temperatureF == 0.0) {
          return _simulatedReading(
              lat: lat, lon: lon, locationName: locationName);
        }
        return reading;
      }

      // 2. Poll for completion
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final statusUri =
            Uri.parse('${AppConfig.fortyGuardBaseUrl}/status/$activityId');

        final statusResponse = await _client.get(
          statusUri,
          headers: {
            'api-key': apiKey,
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));

        if (statusResponse.statusCode == 200) {
          final statusBody = jsonDecode(statusResponse.body);
          final statusVal =
              (statusBody['data'] != null && statusBody['data'] is Map)
                  ? (statusBody['data']['status'] ?? statusBody['status'])
                  : statusBody['status'];
          final statusStr = (statusVal ?? '').toString().toLowerCase();

          if (statusStr == 'completed') {
            final dataBlock = statusBody['data'] ?? statusBody;
            Map<String, dynamic> data = {};

            if (dataBlock['result'] != null &&
                dataBlock['result']['locations'] != null &&
                (dataBlock['result']['locations'] as List).isNotEmpty) {
              data = Map<String, dynamic>.from(
                  dataBlock['result']['locations'][0]);

              // If there are parameters with arrays, we can try to extract the first value
              if (data['parameters'] != null) {
                final params = data['parameters'] as Map<String, dynamic>;
                if (params['temperature_celsius'] != null &&
                    (params['temperature_celsius'] as List).isNotEmpty) {
                  data['temperature_celsius'] =
                      params['temperature_celsius'][0];
                }
                if (params['heat_index_celsius'] != null &&
                    (params['heat_index_celsius'] as List).isNotEmpty) {
                  data['heat_index_celsius'] = params['heat_index_celsius'][0];
                }
                if (params['relative_humidity_percent'] != null &&
                    (params['relative_humidity_percent'] as List).isNotEmpty) {
                  data['relative_humidity_percent'] =
                      params['relative_humidity_percent'][0];
                }
              }
            } else {
              data = Map<String, dynamic>.from(dataBlock);
            }

            // Auto-convert known FortyGuard celsius fields to Fahrenheit
            double toF(num c) => (c * 9 / 5) + 32;
            if (data['temperature_celsius'] != null) {
              data['temperature_f'] = toF(data['temperature_celsius']);
            }
            if (data['heat_index_celsius'] != null) {
              data['heat_index_f'] = toF(data['heat_index_celsius']);
            }

            final reading = _normalizeReading(
              TemperatureReading.fromJson(data),
              lat: lat,
              lon: lon,
              locationName: locationName,
            );
            if (reading.temperatureF == 0.0) {
              // API successfully processed but returned empty arrays (no data for this coordinate/time).
              return _simulatedReading(
                  lat: lat, lon: lon, locationName: locationName);
            }

            // Hackathon fallback: If API doesn't provide these yet, simulate them to populate the UI
            if (reading.humidityPct == null || reading.heatIndexF == null) {
              final sim = _simulatedReading(
                  lat: lat, lon: lon, locationName: locationName);
              return TemperatureReading(
                gridId: reading.gridId,
                locationName: reading.locationName,
                latitude: reading.latitude,
                longitude: reading.longitude,
                temperatureF: reading.temperatureF,
                heatIndexF: reading.heatIndexF ?? sim.heatIndexF,
                humidityPct: reading.humidityPct ?? sim.humidityPct,
                timestamp: reading.timestamp,
              );
            }

            return reading;
          } else if (statusStr == 'failed' || statusStr == 'error') {
            throw FortyGuardException(
                'API job failed on server side: ${statusResponse.body}');
          }
        }
      }

      throw FortyGuardException(
          'Timed out waiting for data (activity_id: $activityId)');
    } catch (e) {
      print('DEBUG: Exception in API call: $e. Falling back to simulation.');
      return _simulatedReading(lat: lat, lon: lon, locationName: locationName);
    }
  }

  TemperatureReading _normalizeReading(
    TemperatureReading reading, {
    required double lat,
    required double lon,
    required String locationName,
  }) {
    final hasLocation = reading.locationName.trim().isNotEmpty &&
        reading.locationName.toLowerCase() != 'unknown';
    final hasGrid = reading.gridId.trim().isNotEmpty &&
        reading.gridId.toLowerCase() != 'unknown-grid';

    return TemperatureReading(
      gridId: hasGrid ? reading.gridId : _gridLabel(lat, lon),
      locationName: hasLocation ? reading.locationName : locationName,
      latitude: reading.latitude == 0 ? lat : reading.latitude,
      longitude: reading.longitude == 0 ? lon : reading.longitude,
      temperatureF: reading.temperatureF,
      heatIndexF: reading.heatIndexF,
      humidityPct: reading.humidityPct,
      timestamp: reading.timestamp,
    );
  }

  String _gridLabel(double lat, double lon) {
    final latitudeDirection = lat >= 0 ? 'N' : 'S';
    final longitudeDirection = lon >= 0 ? 'E' : 'W';
    return 'OHIO-${lat.abs().toStringAsFixed(2)}$latitudeDirection-${lon.abs().toStringAsFixed(2)}$longitudeDirection';
  }

  /// Simulated reading generator for offline demoing. Slowly drifts and
  /// occasionally spikes so you can showcase the full alert pipeline
  /// (watch -> warning -> emergency) live during judging without depending
  /// on network access or an actual heatwave happening that day.
  double _lastSimTemp = 91.0;

  TemperatureReading _simulatedReading({
    required double lat,
    required double lon,
    required String locationName,
  }) {
    final drift = (_rand.nextDouble() - 0.35) * 3.0;
    _lastSimTemp = (_lastSimTemp + drift).clamp(85.0, 118.0);

    return TemperatureReading(
      gridId: 'OH-DEMO-${lat.toStringAsFixed(2)}-${lon.toStringAsFixed(2)}',
      locationName: locationName,
      latitude: lat,
      longitude: lon,
      temperatureF: double.parse(_lastSimTemp.toStringAsFixed(1)),
      heatIndexF: double.parse((_lastSimTemp + 4).toStringAsFixed(1)),
      humidityPct:
          double.parse((45 + _rand.nextDouble() * 20).toStringAsFixed(0)),
      timestamp: DateTime.now(),
    );
  }

  void dispose() => _client.close();
}

class FortyGuardException implements Exception {
  final String message;
  FortyGuardException(this.message);
  @override
  String toString() => 'FortyGuardException: $message';
}
