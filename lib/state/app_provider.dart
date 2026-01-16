import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'package:daily_reminder/models/medicine_inventory.dart';
import 'package:daily_reminder/models/reminder_model.dart';
import 'package:daily_reminder/models/settings_model.dart';
import 'package:daily_reminder/services/storage_service.dart';
import 'package:daily_reminder/services/notification_service.dart';
import 'package:daily_reminder/services/voice_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final VoiceService _voiceService = VoiceService();
  final AudioPlayer _audioPlayer = AudioPlayer();


  List<Reminder> _reminders = [];
  List<MedicineInventory> _inventory = []; 
  Settings _settings = Settings();

  List<Reminder> get reminders => _reminders;
  List<MedicineInventory> get inventory => _inventory; 
  Settings get settings => _settings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;


  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _notificationService.init();

    // Load Settings
    final settingsMap = await _storageService.loadSettings();
    if (settingsMap != null) {
      _settings = Settings.fromJson(settingsMap);
    }
    
    // Load Inventory
    final inventoryData = await _storageService.loadMedicineInventory();
    _inventory = inventoryData.map((e) => MedicineInventory.fromJson(e)).toList();

    // Check for new day
    bool isNewDay = await _storageService.isNewDay();

    // Load Reminders
    final remindersData = await _storageService.loadReminders();
    if (remindersData.isEmpty) {
      _reminders = _generateDefaultReminders();
    } else {
      _reminders = remindersData.map((e) => Reminder.fromJson(e)).toList();
      if (isNewDay) {
        _resetDailyProgress();
      }
    }

    _scheduleAllNotifications();
    _listenToNotifications(); 
    _isLoading = false;
    notifyListeners();
  }

  void _listenToNotifications() {
    NotificationService.onNotifications.stream.listen((response) {
      if (response.actionId == 'done' || response.actionId == 'snooze') {
        _voiceService.stop();
        _stopWakeUpSong(); 
        
        if (response.actionId == 'done') {
          final payloadId = int.tryParse(response.payload ?? '');
          if (payloadId != null) {
            _handleDoneAction(payloadId);
          }
        }
      } else if (response.payload != null && response.payload != 'test') {
        _handleBodyTapAction(response.payload!);
      }
    });
  }


  void _handleBodyTapAction(String payload) async {
    print("🗣️ _handleBodyTapAction called with payload: $payload");
    if (payload == 'inventory') {
      speak("Your medicine stock is running low. Please check the tracker and restock soon.");
      return;
    }

    final id = int.tryParse(payload);
    if (id != null) {
      String? reminderId;
      final int base = (id / 1000).floor() * 1000;
      
      switch (base) {
        case 1000: reminderId = 'wake'; break;
        case 2000: reminderId = 'breakfast'; break;
        case 3000: reminderId = 'lunch'; break;
        case 4000: reminderId = 'walk'; break;
        case 5000: reminderId = 'dinner'; break;
        case 6000: reminderId = 'sleep'; break;
      }

      if (reminderId != null) {
        final reminder = _reminders.firstWhereOrNull((r) => r.id == reminderId);
        if (reminder == null) return;

        final bool isMedicineReminder = (id % 1000 == 100);
        
        if (isMedicineReminder) {
          final medNames = reminder.medicines.map((m) => m.name).join(", ");
          print("🗣️ Speaking medicine reminder for ${reminder.title}");
          await speak("Hello! 🌸 Could you please take your ${reminder.title} medicines now? It's time for $medNames. ❤️");
        } else {
          String greeting = "Hey! ✨";
          String closing = "Have a wonderful day! 🌈";
          
          if (reminderId == 'wake') {
            greeting = "Rise and shine, morning sunshine! ☀️";
            closing = "Let's start this beautiful day together. 😊";
          } else if (reminderId == 'breakfast') {
            greeting = "Good morning! 🍳";
            closing = "Enjoy your delicious breakfast! 🍎";
          } else if (reminderId == 'lunch') {
            greeting = "Good afternoon! 🍱";
            closing = "Wishing you a peaceful and tasty lunch. 🥗";
          } else if (reminderId == 'walk') {
            greeting = "Hello there! 🚶";
            closing = "A gentle walk will feel so refreshing for you. 🌳";
          } else if (reminderId == 'dinner') {
            greeting = "Good evening! 🍛";
            closing = "Time for a lovely dinner and some rest. ❤️";
          } else if (reminderId == 'sleep') {
            greeting = "Good night and sweet dreams! 🌙";
            final wakeReminder = _reminders.firstWhereOrNull((r) => r.id == 'wake');
            if (wakeReminder != null) {
              final timeStr = "${wakeReminder.hour % 12 == 0 ? 12 : wakeReminder.hour % 12}:${wakeReminder.minute.toString().padLeft(2, '0')} ${wakeReminder.hour >= 12 ? 'PM' : 'AM'}";
              closing = "You've done so well today. Please remember to set your phone alarm for $timeStr to wake up tomorrow!";
            }
          }

          print("🗣️ Triggering voice reminder for ${reminder.title}");
          await speak("$greeting Reminder: It is time for ${reminder.title}. $closing");
          
          if (reminderId == 'wake') {
            print("🎵 Scheduling wake-up song with 8-second delay...");
            Future.delayed(const Duration(seconds: 8), () {
              _playWakeUpSong();
            });
          }
        }
      }
    } else if (payload == 'test') {
      speak("This is a test notification. Voice alerts are working!");
    }
  }

  void _playWakeUpSong() async {
    print("🎵 _playWakeUpSong called");
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('alarm.mp3'));
      Future.delayed(const Duration(minutes: 1), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      print("🎵 AudioPlayer error: $e");
    }
  }

  void _stopWakeUpSong() {
    try {
      _audioPlayer.stop();
    } catch (e) {
      print("AudioPlayer stop error: $e");
    }
  }

  void _handleDoneAction(int notificationId) {
    _stopWakeUpSong();
    _voiceService.stop();
    
    // Determine which reminder this belongs to
    // Reminder bases: 100 (wake), 200 (breakfast), 300 (lunch), 400 (walk), 500 (dinner), 600 (sleep)
    // Medicine IDs are base + 100
    if (notificationId == 999) {
      // Test notification - just show a toast or log
      print("✅ Test notification DONE clicked!");
      return;
    }

    // Find the reminder by notification ID
    Reminder? targetReminder;
    bool isMedicineNotification = false;

    if (notificationId >= 1000 && notificationId < 2000) {
      targetReminder = _reminders.firstWhereOrNull((r) => r.id == 'wake');
    } else if (notificationId >= 2000 && notificationId < 3000) {
      targetReminder = _reminders.firstWhereOrNull((r) => r.id == 'breakfast');
      isMedicineNotification = notificationId >= 2100;
    } else if (notificationId >= 3000 && notificationId < 4000) {
      targetReminder = _reminders.firstWhereOrNull((r) => r.id == 'lunch');
      isMedicineNotification = notificationId >= 3100;
    } else if (notificationId >= 4000 && notificationId < 5000) {
      targetReminder = _reminders.firstWhereOrNull((r) => r.id == 'walk');
    } else if (notificationId >= 5000 && notificationId < 6000) {
      targetReminder = _reminders.firstWhereOrNull((r) => r.id == 'dinner');
      isMedicineNotification = notificationId >= 5100;
    } else if (notificationId >= 6000 && notificationId < 7000) {
      targetReminder = _reminders.firstWhereOrNull((r) => r.id == 'sleep');
    }

    if (targetReminder != null) {
      if (isMedicineNotification) {
        // Mark ALL medicines as taken
        for (var med in targetReminder.medicines) {
          if (!med.isTaken) { // Only update if not already taken
            toggleMedicineTaken(targetReminder.id, med.id, true);
          }
        }
      } else {
        // Mark meal/activity as completed
        toggleMealCompletion(targetReminder.id, true);
      }
      // _saveReminders() and notifyListeners() are called by toggleMedicineTaken/toggleMealCompletion
    }
  }


  // --- Actions ---

  void updateSettings(Settings newSettings) {
    _settings = newSettings;
    _storageService.saveSettings(_settings.toJson());
    notifyListeners();
  }

  void updateReminderTime(String id, int hour, int minute) {
    int index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(hour: hour, minute: minute);
      _saveReminders();
      _scheduleNotification(_reminders[index]);
      notifyListeners();
    }
  }

  void updateMedicineTime(String id, int hour, int minute) {
    int index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(medicineHour: hour, medicineMinute: minute);
      _saveReminders();
      _scheduleNotification(_reminders[index]); 
      notifyListeners();
    }
  }

  // Meal/Activity Checkbox
  void toggleMealCompletion(String id, bool? value) {
    int index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(isCompleted: value ?? false);
      _saveReminders();
      notifyListeners();
    }
  }

  // Individual Medicine Checkbox
  void toggleMedicineTaken(String reminderId, String medicineId, bool? value) {
    int index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      List<Medicine> updatedMeds = List.from(_reminders[index].medicines);
      int medIndex = updatedMeds.indexWhere((m) => m.id == medicineId);
      if (medIndex != -1) {
        final medicine = updatedMeds[medIndex];
        final bool isTaking = value ?? false;
        final bool wasTaken = medicine.isTaken;

        // Update medicine state
        updatedMeds[medIndex] = medicine.copyWith(isTaken: isTaking);
        _reminders[index] = _reminders[index].copyWith(medicines: updatedMeds);
        
        // Update Inventory Stock automatically
        if (isTaking != wasTaken) {
          _updateInventoryFromDose(medicine.name, medicine.dosage, isTaking);
        }

        _saveReminders();
        notifyListeners();
      }
    }
  }

  void _updateInventoryFromDose(String medName, String dosageStr, bool isAdding) {
    // Find matching inventory item (case-insensitive and trimmed)
    final normalizedSearchName = medName.trim().toLowerCase();
    int invIndex = _inventory.indexWhere((i) => i.name.trim().toLowerCase() == normalizedSearchName);
    
    if (invIndex != -1) {
      print("📊 Inventory Match Found: $medName -> ${_inventory[invIndex].name}");
      // Parse dosage (look for the first number)
      final RegExp numRegExp = RegExp(r'(\d+)');
      final match = numRegExp.firstMatch(dosageStr);
      int? amount = match != null ? int.tryParse(match.group(1)!) : 1;

      if (isAdding) {
        // Taken the medicine -> Reduce stock
        _inventory[invIndex] = _inventory[invIndex].copyWith(
          currentStock: (_inventory[invIndex].currentStock - (amount ?? 1)).clamp(0, 9999)
        );
        
        // Check for low stock notification
        if (_inventory[invIndex].isLowStock) {
           print("⚠️ TRIGGERING LOW STOCK NOTIF for ${_inventory[invIndex].name}");
          _notificationService.showNotification(
            id: 888 + invIndex, // Unique-ish ID
            title: "Medicine Running Low! 💊",
            body: "Only ${_inventory[invIndex].currentStock} ${_inventory[invIndex].name} pills left. Please restock soon!",
            payload: 'inventory',
          );
        }
      } else {
        // Unchecked -> Add stock back
        _inventory[invIndex] = _inventory[invIndex].copyWith(
          currentStock: _inventory[invIndex].currentStock + (amount ?? 1)
        );
      }
      _saveInventory();
    } else {
      print("❓ No inventory match for medicine: $medName (Searched for: $normalizedSearchName)");
    }
  }

  // Add/Edit Medicine
  void addMedicine(String reminderId, String name, String dosage) {
    int index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      List<Medicine> updatedMeds = List.from(_reminders[index].medicines);
      updatedMeds.add(Medicine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        dosage: dosage,
      ));
      _reminders[index] = _reminders[index].copyWith(medicines: updatedMeds);
      _saveReminders();
      notifyListeners();
    }
  }

  void removeMedicine(String reminderId, String medicineId) {
    int index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
       List<Medicine> updatedMeds = List.from(_reminders[index].medicines);
       updatedMeds.removeWhere((m) => m.id == medicineId);
       _reminders[index] = _reminders[index].copyWith(medicines: updatedMeds);
       _saveReminders();
       notifyListeners();
    }
  }
  
  // --- Inventory Actions ---
  
  void addInventoryItem(String name, int currentStock) {
    _inventory.add(MedicineInventory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentStock: currentStock,
    ));
    _saveInventory();
    notifyListeners();
  }

  void updateInventoryStock(String id, int newStock) {
    int index = _inventory.indexWhere((i) => i.id == id);
    if (index != -1) {
      _inventory[index] = _inventory[index].copyWith(currentStock: newStock);
      _saveInventory();
      notifyListeners();
    }
  }

  void deleteInventoryItem(String id) {
    _inventory.removeWhere((i) => i.id == id);
    _saveInventory();
    notifyListeners();
  }
  
  Future<void> _saveInventory() async {
    await _storageService.saveMedicineInventory(_inventory.map((e) => e.toJson()).toList());
  }

  
  Future<void> speak(String text) async {
    print("📢 AppProvider.speak() - isVoiceEnabled: ${_settings.isVoiceEnabled}");
    if (_settings.isVoiceEnabled) {
      // Strip emojis for clear reading
      final cleanText = text.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E6}-\u{1F1FF}]', unicode: true), '');
      await _voiceService.speak(cleanText); 
    }
  }

  // Merged: test method restored for internal usage if needed
  Future<void> sendTestNotification() async {
     final msg = "This is a test notification. Voice alerts are working!";
     _notificationService.showNotification(
       id: 999,
       title: "Test Reminder 🔔",
       body: msg,
       payload: 'test',
     );
     speak(msg);
  }


  Future<void> _saveReminders() async {
    await _storageService.saveReminders(_reminders.map((e) => e.toJson()).toList());
  }

  void _resetDailyProgress() {
    for (int i = 0; i < _reminders.length; i++) {
      final meds = _reminders[i].medicines.map((m) => m.copyWith(isTaken: false)).toList();
      _reminders[i] = _reminders[i].copyWith(isCompleted: false, medicines: meds);
    }
    _saveReminders();
  }

  void _scheduleAllNotifications() {
     _notificationService.cancelAll();
     for (var reminder in _reminders) {
       _scheduleNotification(reminder);
     }
  }

  void _scheduleNotification(Reminder reminder) {
    int idBase = _getNotificationIdBase(reminder.id);
    
    // 1. Schedule Meal/Activity Reminder
    _notificationService.scheduleDailyNotification(
      id: idBase,
      title: reminder.hasMedicines ? "Meal: ${reminder.title} 🥗" : "${reminder.title} ✨",
      body: _notificationService.getNiceMessage(
        reminder.hasMedicines ? 'Meal' : 'Activity',
        reminderId: reminder.id,
      ),
      hour: reminder.hour,
      minute: reminder.minute,
    );

    // 2. Schedule Medicine Reminder (if exists)
    if (reminder.hasMedicines && reminder.medicines.isNotEmpty) {
       int medHour = reminder.medicineHour ?? reminder.hour;
       int medMinute = reminder.medicineMinute ?? reminder.minute;
       
       _notificationService.scheduleDailyNotification(
         id: idBase + 100, 
         title: "Medicines for ${reminder.title} 💊",
         body: _notificationService.getNiceMessage("Medicines", reminderId: reminder.id),
         hour: medHour,
         minute: medMinute,
       );
    }
  }

  int _getNotificationIdBase(String id) {
    switch (id) {
      case 'wake': return 1000;
      case 'breakfast': return 2000;
      case 'lunch': return 3000;
      case 'walk': return 4000;
      case 'dinner': return 5000;
      case 'sleep': return 6000;
      default: return 9000;
    }
  }

  List<Reminder> _generateDefaultReminders() {
    return [
      Reminder(id: 'wake', title: 'Wake Up', hour: 6, minute: 0, hasMedicines: false),
      Reminder(
        id: 'breakfast', 
        title: 'Breakfast', 
        hour: 8, 
        minute: 0, 
        hasMedicines: true,
        medicines: [
          Medicine(id: '1', name: 'Medicine 1', dosage: '1 tablet'),
          Medicine(id: '2', name: 'Medicine 2', dosage: '1 tablet'),
        ],
        medicineHour: 8,
        medicineMinute: 30, 
      ),
      Reminder(
        id: 'lunch', 
        title: 'Lunch', 
        hour: 13, 
        minute: 0, 
        hasMedicines: true,
        medicines: [
          Medicine(id: '3', name: 'Medicine 1', dosage: '1 tablet'),
        ],
        medicineHour: 13,
        medicineMinute: 30,
      ),
      Reminder(id: 'walk', title: 'Walk', hour: 17, minute: 0, hasMedicines: false),
      Reminder(
        id: 'dinner', 
        title: 'Dinner', 
        hour: 20, 
        minute: 0, 
        hasMedicines: true,
        medicines: [
           Medicine(id: '4', name: 'Medicine 1', dosage: '1 tablet'),
        ],
        medicineHour: 20,
        medicineMinute: 30,
      ),
      Reminder(id: 'sleep', title: 'Sleep', hour: 22, minute: 0, hasMedicines: false),
    ];
  }
}
