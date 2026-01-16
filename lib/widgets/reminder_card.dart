import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../state/app_provider.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Meal Logic
    final isMealCompleted = reminder.isCompleted;

    // Medicine Logic
    final bool allMedsTaken = reminder.isMedicinesCompleted;
    
    // Formatting Meal Time
    final hour = reminder.hour == 0 ? 12 : (reminder.hour > 12 ? reminder.hour - 12 : reminder.hour);
    final minute = reminder.minute.toString().padLeft(2, '0');
    final period = reminder.hour >= 12 ? 'PM' : 'AM';
    final mealTimeString = "$hour:$minute $period";

    // Formatting Medicine Time
    final mHourRaw = reminder.medicineHour ?? reminder.hour;
    final mMinuteRaw = reminder.medicineMinute ?? reminder.minute;
    final mHour = mHourRaw == 0 ? 12 : (mHourRaw > 12 ? mHourRaw - 12 : mHourRaw);
    final mMinute = mMinuteRaw.toString().padLeft(2, '0');
    final mPeriod = mHourRaw >= 12 ? 'PM' : 'AM';
    final medTimeString = "$mHour:$mMinute $mPeriod";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade300, width: 1),
      ),
      color: const Color(0xFFE0F2F1), // Original light teal
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- SECTION 1: MEAL REMINDER ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.teal),
                            onPressed: () async {
                              String greeting = "Hey! ✨ ";
                              String closing = "Have a wonderful day! 🌈";
                              
                              if (reminder.id == 'wake') greeting = "Rise and shine! ☀️ ";
                              if (reminder.id == 'sleep') closing = "Rest well! ✨";

                              // Speak Meal first
                              await provider.speak("$greeting It is time for ${reminder.title}. $closing");
                              
                              // Then Medicines if any
                              if (reminder.hasMedicines && reminder.medicines.isNotEmpty) {
                                final medNames = reminder.medicines.map((m) => m.name).join(", ");
                                await provider.speak("Hello! 🌸 It is time for your ${reminder.title} medicines: $medNames. ❤️");
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mealTimeString,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 1.3,
                  child: Checkbox(
                    value: isMealCompleted,
                    activeColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      provider.toggleMealCompletion(reminder.id, val);
                    },
                  ),
                ),
              ],
            ),
            
            // --- SECTION 2: MEDICINE REMINDER (Conditional) ---
            if (reminder.hasMedicines && reminder.medicines.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.teal, thickness: 0.5),
              const SizedBox(height: 8),
              
              Row(
                children: [
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text(
                            "Medicine Reminder",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            medTimeString,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                       ],
                     ),
                   ),
                  Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                      value: allMedsTaken,
                      activeColor: Colors.deepOrange,
                      onChanged: (val) {
                        for (var med in reminder.medicines) {
                          provider.toggleMedicineTaken(reminder.id, med.id, val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...reminder.medicines.map((med) {
                 return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              med.dosage,
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade900, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: med.isTaken,
                          activeColor: Colors.orange, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                             provider.toggleMedicineTaken(reminder.id, med.id, val);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
