import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_provider.dart';
import '../widgets/reminder_card.dart';
import 'settings_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Reminder"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings'),
                ),
              ];
            },
          ),
        ],
      ),
      // No FAB for production
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.reminders.length,
            itemBuilder: (context, index) {
              final reminder = provider.reminders[index];
              final lowStockMeds = provider.inventory.where((i) => i.daysLeft <= 4).toList();
              
              final Widget card = ReminderCard(reminder: reminder);

              // If this is the Sleep reminder and there are low stock meds, show the warning below it
              if (reminder.id == 'sleep' && lowStockMeds.isNotEmpty) {
                return Column(
                  children: [
                    card,
                    const SizedBox(height: 8),
                    ...lowStockMeds.map((med) => Card(
                      color: Colors.red.shade50,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        title: Text(
                          "Restock ${med.name} Soon!",
                          style: const TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Only ${med.daysLeft} days remaining", style: const TextStyle(fontSize: 18, color: Colors.black87)),
                        trailing: TextButton(
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                          },
                          child: const Text("UPDATE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    )),
                  ],
                );
              }

              return card;
            },
          );
        },
      ),
    );
  }
}
