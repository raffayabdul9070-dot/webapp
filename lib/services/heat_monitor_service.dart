import 'dart:async';

import '../config/app_config.dart';
import '../models/heat_alert.dart';
import '../models/temperature_reading.dart';
import '../utils/heat_risk.dart';
import 'alert_dispatch_service.dart';
import 'fortyguard_service.dart';

/// The autonomous workflow at the heart of the system: continuously polls
/// FortyGuard's feed for the target grid, classifies each reading, and
/// fires a [HeatAlert] through [AlertDispatchService] the moment severity
/// increases past the last known level (so residents/responders aren't
/// spammed every 5 minutes while heat stays in the same band).
class HeatMonitorService {
  final FortyGuardService _fortyGuard;
  final AlertDispatchService _dispatcher;

  final _readingController = StreamController<TemperatureReading>.broadcast();
  final _alertController = StreamController<HeatAlert>.broadcast();

  Timer? _timer;
  HeatSeverity _lastSeverity = HeatSeverity.normal;
  final List<HeatAlert> alertHistory = [];
  final List<TemperatureReading> readingHistory = [];
  int _alertCounter = 0;

  HeatMonitorService({
    FortyGuardService? fortyGuard,
    AlertDispatchService? dispatcher,
  })  : _fortyGuard = fortyGuard ?? FortyGuardService(),
        _dispatcher = dispatcher ?? AlertDispatchService();

  Stream<TemperatureReading> get readings => _readingController.stream;
  Stream<HeatAlert> get alerts => _alertController.stream;
  HeatSeverity get currentSeverity => _lastSeverity;

  /// Starts the autonomous polling loop.
  void start({Duration? interval}) {
    _timer?.cancel();
    _poll(); // fire immediately so the UI isn't empty on launch
    _timer = Timer.periodic(interval ?? AppConfig.pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final reading = await _fortyGuard.fetchCurrentReading();
      readingHistory.add(reading);
      if (readingHistory.length > 100) readingHistory.removeAt(0);
      _readingController.add(reading);

      final severity = HeatRisk.classify(reading);

      // Only raise a new alert when severity escalates, so we don't spam
      // the same warning every poll cycle. A drop back to normal also
      // resets the state so the next escalation triggers fresh.
      final severityRank = HeatSeverity.values.indexOf(severity);
      final lastRank = HeatSeverity.values.indexOf(_lastSeverity);

      if (severity != HeatSeverity.normal && severityRank >= lastRank) {
        final alert = HeatAlert(
          id: 'alert-${DateTime.now().millisecondsSinceEpoch}-${_alertCounter++}',
          severity: severity,
          reading: reading,
          createdAt: DateTime.now(),
        );
        alertHistory.insert(0, alert);
        _alertController.add(alert);
        await _dispatcher.dispatch(alert);
      }

      _lastSeverity = severity;
    } catch (e) {
      // Surface fetch errors on the reading stream's error channel so the
      // UI can show a "feed unavailable" state without killing the loop.
      _readingController.addError(e);
    }
  }

  /// Manually forces a poll — handy for a "Check Now" demo button.
  Future<void> pollOnce() => _poll();

  void dispose() {
    _timer?.cancel();
    _readingController.close();
    _alertController.close();
    _fortyGuard.dispose();
  }
}
