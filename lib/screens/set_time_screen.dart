import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_provider.dart'; // Import for Medicine class if needed

class SetTimeScreen extends StatelessWidget {
  const SetTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final reminders = provider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Timings & Dosage"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          
          final hour = reminder.hour == 0 ? 12 : (reminder.hour > 12 ? reminder.hour - 12 : reminder.hour);
          final minute = reminder.minute.toString().padLeft(2, '0');
          final period = reminder.hour >= 12 ? 'PM' : 'AM';
          final timeString = "$hour:$minute $period";

          // Medicine Time
          final mHourRaw = reminder.medicineHour ?? reminder.hour;
          final mMinuteRaw = reminder.medicineMinute ?? reminder.minute;
          final mHour = mHourRaw == 0 ? 12 : (mHourRaw > 12 ? mHourRaw - 12 : mHourRaw);
          final mMinute = mMinuteRaw.toString().padLeft(2, '0');
          final mPeriod = mHourRaw >= 12 ? 'PM' : 'AM';
          final mTimeString = "$mHour:$mMinute $mPeriod";

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Meal Time
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                         icon: const Icon(Icons.access_time, size: 28),
                         label: Text(
                           "${reminder.hasMedicines ? 'Meal' : 'Time'}: $timeString",
                           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                         ),
                         onPressed: () async {
                           final TimeOfDay? picked = await showTimePicker(
                             context: context,
                             initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
                           );
                           if (picked != null) {
                             provider.updateReminderTime(reminder.id, picked.hour, picked.minute);
                           }
                         },
                      ),
                    ],
                  ),
                  
                  if (reminder.hasMedicines) ...[
                    const Divider(),
                    // Medicine Time Row
                     Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text("Medicines Schedule: ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                             icon: const Icon(Icons.notifications_active_outlined, size: 28),
                             label: Text("Meds: $mTimeString", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                             onPressed: () async {
                               final TimeOfDay? picked = await showTimePicker(
                                 context: context,
                                 initialTime: TimeOfDay(hour: mHourRaw, minute: mMinuteRaw),
                               );
                               if (picked != null) {
                                 provider.updateMedicineTime(reminder.id, picked.hour, picked.minute);
                               }
                             },
                          ),
                        ],
                     ),
                    const SizedBox(height: 8),
                    const Text("Prescription List:", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    
                    // List of Medicines
                    ...reminder.medicines.map((med) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(med.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      subtitle: Text(med.dosage, style: const TextStyle(fontSize: 18, color: Colors.black87)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                           provider.removeMedicine(reminder.id, med.id);
                        },
                      ),
                    )),
                    
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          _showAddMedicineDialog(context, provider, reminder.id);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Medicine"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context, AppProvider provider, String reminderId) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController dosageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Medicine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Medicine Name"),
            ),
            TextField(
              controller: dosageCtrl,
              decoration: const InputDecoration(labelText: "Dosage (e.g. 1 pill)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && dosageCtrl.text.isNotEmpty) {
                provider.addMedicine(reminderId, nameCtrl.text, dosageCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
