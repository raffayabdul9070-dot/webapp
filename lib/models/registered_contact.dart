/// A registered resident or emergency responder tied to a specific grid,
/// used to target alerts to only the neighborhood(s) affected.
///
/// In a production build this list would come from a backend (Firestore,
/// a city registration database, etc.). For the hackathon demo it's kept
/// in-memory / local so judges can see targeted routing without needing
/// backend infra.
class RegisteredContact {
  final String id;
  final String name;
  final String gridId;
  final ContactRole role;
  final bool vulnerable; // e.g. elderly, medical condition, no AC
  final String contactMethod; // sms / push / email — display only in demo

  const RegisteredContact({
    required this.id,
    required this.name,
    required this.gridId,
    required this.role,
    this.vulnerable = false,
    this.contactMethod = 'push',
  });
}

enum ContactRole { resident, responder }
