import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? _currentManualUid;
  String? _currentManualRole;
  
  String? get currentUid => _currentManualUid;
  String? get currentRole => _currentManualRole;

  // Initialize from storage on app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentManualUid = prefs.getString('manual_uid');
    _currentManualRole = prefs.getString('manual_role');
    notifyListeners();
  }

  Future<void> setManualUid(String uid, {String? role}) async {
    _currentManualUid = uid;
    _currentManualRole = role;
    final prefs = await SharedPreferences.getInstance();
    if (uid.isNotEmpty) {
      await prefs.setString('manual_uid', uid);
    } else {
      await prefs.remove('manual_uid');
    }
    
    if (role != null) {
      await prefs.setString('manual_role', role);
    } else {
      await prefs.remove('manual_role');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _currentManualUid = null;
    _currentManualRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('manual_uid');
    await prefs.remove('manual_role');
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}
