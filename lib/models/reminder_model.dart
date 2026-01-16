class Medicine {
  final String id;
  final String name;
  final String dosage;
  final bool isTaken;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    this.isTaken = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'isTaken': isTaken,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      isTaken: json['isTaken'] ?? false,
    );
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    bool? isTaken,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      isTaken: isTaken ?? this.isTaken,
    );
  }
}

class Reminder {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final bool isCompleted; // This is now strictly for the MEAL/Activity itself
  final bool hasMedicines;
  
  // New Medicine fields
  final List<Medicine> medicines;
  final int? medicineHour;
  final int? medicineMinute;

  Reminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.isCompleted = false,
    this.hasMedicines = false,
    this.medicines = const [],
    this.medicineHour,
    this.medicineMinute,
  });

  bool get isMedicinesCompleted {
    if (medicines.isEmpty) return false;
    return medicines.every((m) => m.isTaken);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hour': hour,
      'minute': minute,
      'isCompleted': isCompleted,
      'hasMedicines': hasMedicines,
      'medicines': medicines.map((m) => m.toJson()).toList(),
      'medicineHour': medicineHour,
      'medicineMinute': medicineMinute,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      hour: json['hour'],
      minute: json['minute'],
      isCompleted: json['isCompleted'] ?? false,
      hasMedicines: json['hasMedicines'] ?? false,
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((e) => Medicine.fromJson(e))
              .toList() ??
          [],
      medicineHour: json['medicineHour'],
      medicineMinute: json['medicineMinute'],
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    int? hour,
    int? minute,
    bool? isCompleted,
    bool? hasMedicines,
    List<Medicine>? medicines,
    int? medicineHour,
    int? medicineMinute,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isCompleted: isCompleted ?? this.isCompleted,
      hasMedicines: hasMedicines ?? this.hasMedicines,
      medicines: medicines ?? this.medicines,
      medicineHour: medicineHour ?? this.medicineHour,
      medicineMinute: medicineMinute ?? this.medicineMinute,
    );
  }
}
