import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyReminders = 'reminders';
  static const String _keySettings = 'settings';
  static const String _keyLastOpenedDate = 'last_opened_date';

  Future<void> saveReminders(List<Map<String, dynamic>> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminders, jsonEncode(reminders));
  }

  Future<List<Map<String, dynamic>>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyReminders);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings));
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keySettings);
    if (data == null) return null;
    return Map<String, dynamic>.from(jsonDecode(data));
  }


  // --- Inventory ---
  static const String _keyInventory = 'medicine_inventory';

  Future<List<Map<String, dynamic>>> loadMedicineInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyInventory);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> saveMedicineInventory(List<Map<String, dynamic>> inventory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInventory, jsonEncode(inventory));
  }

  /// Returns true if it's a new day since last open
  Future<bool> isNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastDate = prefs.getString(_keyLastOpenedDate);
    final String today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != today) {
      await prefs.setString(_keyLastOpenedDate, today);
      return true;
    }
    return false;
  }
}
