import 'lib/services/fortyguard_service.dart';

void main() async {
  print('Starting FortyGuardService test...');
  final service = FortyGuardService();
  try {
    final reading = await service.fetchCurrentReading();
    print('SUCCESS: \$reading');
  } catch (e, st) {
    print('ERROR: \$e');
    print(st);
  } finally {
    service.dispose();
  }
}
