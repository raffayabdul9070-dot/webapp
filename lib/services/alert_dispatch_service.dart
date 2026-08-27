import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/heat_alert.dart';
import '../models/registered_contact.dart';

/// Routes a [HeatAlert] to the responders and residents registered for the
/// affected grid, and surfaces an on-device notification.
///
/// This demo ships a small in-memory contact registry so targeted routing
/// is visible end-to-end. In production, swap [_directory] for a real
/// lookup (Firestore query by gridId, a city 911/CAD system integration,
/// Twilio for SMS, FCM for resident push, etc.) — the dispatch logic below
/// doesn't need to change, only where the contact list comes from.
class AlertDispatchService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Demo contact registry, keyed by gridId prefix so simulated grid ids
  // (e.g. "OH-DEMO-40.42--82.91") still match a sample neighborhood.
  final List<RegisteredContact> _directory = const [
    RegisteredContact(
      id: 'r1',
      name: 'Columbus Fire Dept. — District 3',
      gridId: 'OH',
      role: ContactRole.responder,
    ),
    RegisteredContact(
      id: 'r2',
      name: 'Franklin County Office on Aging',
      gridId: 'OH',
      role: ContactRole.responder,
    ),
    RegisteredContact(
      id: 'u1',
      name: 'Maria G. (Short North)',
      gridId: 'OH',
      role: ContactRole.resident,
      vulnerable: true,
      contactMethod: 'sms',
    ),
    RegisteredContact(
      id: 'u2',
      name: 'James O. (Linden)',
      gridId: 'OH',
      role: ContactRole.resident,
      vulnerable: true,
      contactMethod: 'sms',
    ),
    RegisteredContact(
      id: 'u3',
      name: 'Priya K. (German Village)',
      gridId: 'OH',
      role: ContactRole.resident,
      contactMethod: 'push',
    ),
  ];

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  /// Returns contacts registered for the grid this alert applies to.
  List<RegisteredContact> contactsFor(HeatAlert alert) {
    final gridPrefix = alert.reading.gridId.split('-').first;
    return _directory.where((c) => c.gridId == gridPrefix).toList();
  }

  /// Dispatches the alert: pushes a local notification (stands in for
  /// FCM/SMS/E911 integration in this demo) and marks the alert as sent
  /// to the appropriate audiences based on severity.
  Future<void> dispatch(HeatAlert alert) async {
    await init();

    final contacts = contactsFor(alert);
    final responders = contacts.where((c) => c.role == ContactRole.responder);
    final residents = contacts.where((c) => c.role == ContactRole.resident);

    final title = '${alert.severity.label}: ${alert.reading.locationName}';
    final body =
        '${alert.reading.effectiveTempF.toStringAsFixed(1)}°F in grid ${alert.reading.gridId}. '
        '${alert.severity.description}';

    await _notifications.show(
      alert.id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'heatwave_alerts',
          'Heatwave Alerts',
          channelDescription: 'Critical localized heat threshold alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );

    // Warning+ always notifies responders; watch+ notifies vulnerable
    // residents first, then everyone at warning+.
    if (alert.severity == HeatSeverity.warning ||
        alert.severity == HeatSeverity.emergency) {
      alert.dispatchedToResponders = responders.isNotEmpty;
    }
    if (alert.severity != HeatSeverity.normal) {
      alert.dispatchedToResidents = residents.isNotEmpty;
    }
  }
}
