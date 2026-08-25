import 'temperature_reading.dart';

enum HeatSeverity { normal, watch, warning, emergency }

extension HeatSeverityX on HeatSeverity {
  String get label {
    switch (this) {
      case HeatSeverity.normal:
        return 'Normal';
      case HeatSeverity.watch:
        return 'Heat Watch';
      case HeatSeverity.warning:
        return 'Heat Warning';
      case HeatSeverity.emergency:
        return 'Heat Emergency';
    }
  }

  String get description {
    switch (this) {
      case HeatSeverity.normal:
        return 'Temperatures are within a safe range.';
      case HeatSeverity.watch:
        return 'Elevated heat risk. Vulnerable residents should limit outdoor activity.';
      case HeatSeverity.warning:
        return 'Dangerous heat. Responders should prep cooling resources for this grid.';
      case HeatSeverity.emergency:
        return 'Extreme, life-threatening heat. Immediate response required for this grid.';
    }
  }
}

/// A dispatched (or pending) alert generated when a grid's reading crosses
/// a configured threshold.
class HeatAlert {
  final String id;
  final HeatSeverity severity;
  final TemperatureReading reading;
  final DateTime createdAt;
  bool dispatchedToResponders;
  bool dispatchedToResidents;

  HeatAlert({
    required this.id,
    required this.severity,
    required this.reading,
    required this.createdAt,
    this.dispatchedToResponders = false,
    this.dispatchedToResidents = false,
  });
}
