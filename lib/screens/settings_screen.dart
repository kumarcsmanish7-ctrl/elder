import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_provider.dart';
import 'set_time_screen.dart';
import 'medicine_tracker_screen.dart'; // Import


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isCaregiver = provider.settings.isCaregiver;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Who sets dosage?",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<bool>(
              title: const Text("Elder", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              value: false,
              groupValue: isCaregiver,
              onChanged: (val) {
                if (val != null) {
                  provider.updateSettings(provider.settings.copyWith(isCaregiver: val));
                }
              },
            ),
            RadioListTile<bool>(
              title: const Text("Caregiver", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              value: true,
              groupValue: isCaregiver,
              onChanged: (val) {
                if (val != null) {
                  provider.updateSettings(provider.settings.copyWith(isCaregiver: val));
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Voice Alerts (TTS)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              subtitle: const Text("Read reminders aloud", style: TextStyle(fontSize: 18)),
              value: provider.settings.isVoiceEnabled,
              activeColor: Colors.teal,
              onChanged: (val) {
                provider.updateSettings(provider.settings.copyWith(isVoiceEnabled: val));
              },
            ),
            const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.timer),
                label: const Text("Set / Change Timings"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetTimeScreen()),
                  );
                },
              ),
            ),
             const SizedBox(height: 16),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade400,
                  textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text("Medicine Stocks / Tracker"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MedicineTrackerScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
