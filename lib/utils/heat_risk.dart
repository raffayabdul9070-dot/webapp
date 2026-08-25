import '../config/app_config.dart';
import '../models/heat_alert.dart';
import '../models/temperature_reading.dart';

class HeatRisk {
  HeatRisk._();

  static HeatSeverity classify(TemperatureReading reading) {
    final t = reading.effectiveTempF;
    if (t >= AppConfig.emergencyThresholdF) return HeatSeverity.emergency;
    if (t >= AppConfig.warningThresholdF) return HeatSeverity.warning;
    if (t >= AppConfig.watchThresholdF) return HeatSeverity.watch;
    return HeatSeverity.normal;
  }
}
