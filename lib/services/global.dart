import 'package:firebase_auth/firebase_auth.dart';
import 'session_service.dart';

class Global {
  static String? get uid {
    final manualUid = SessionService().currentUid;
    if (manualUid != null) return manualUid;
    // Standardize on email as the UID since that's how Firestore docs are keyed
    return FirebaseAuth.instance.currentUser?.email?.toLowerCase();
  }

  static String? get email {
    final manualUid = SessionService().currentUid;
    if (manualUid != null && manualUid.contains('@')) return manualUid;
    return FirebaseAuth.instance.currentUser?.email?.toLowerCase();
  }

  static bool get isLoggedIn => uid != null;
}
