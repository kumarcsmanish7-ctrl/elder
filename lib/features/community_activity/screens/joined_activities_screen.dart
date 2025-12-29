import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'activity_details_screen.dart';
import '../models/activity_model.dart';

class JoinedActivitiesScreen extends StatelessWidget {
  const JoinedActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirestoreService().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view joined activities.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scheduled Activities'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('joinedActivities')
            .orderBy('joinedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("You haven't joined any activities yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String activityId = docs[index].id;
              final String status = data['status'] ?? 'registered';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    data['activityName'] ?? 'Unnamed Activity',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("${data['date']} at ${data['time']}"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            status == 'attended' ? Icons.check_circle : 
                            status == 'not_attended' ? Icons.cancel : Icons.info_outline,
                            size: 14,
                            color: status == 'attended' ? Colors.green : 
                                   status == 'not_attended' ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text("Status: ${status.toUpperCase()}", 
                            style: TextStyle(
                              color: status == 'attended' ? Colors.green : 
                                     status == 'not_attended' ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _navigateToDetails(context, activityId),
                        child: const Text("Details"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmUnregister(context, activityId, data['activityName'] ?? 'this activity'),
                        tooltip: 'Delete Registration',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmUnregister(BuildContext context, String activityId, String activityName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Registration?"),
        content: Text("Are you sure you want to remove '$activityName' from your scheduled activities?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Back")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Remove", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirestoreService().unregisterActivity(activityId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Registration removed.')),
        );
      }
    }
  }

  void _navigateToDetails(BuildContext context, String activityId) async {
    // We need to fetch the full activity object to show the details screen correctly
    // Since ActivityDetailsScreen expects an Activity object.
    try {
      final doc = await FirebaseFirestore.instance
          .collection('community_activities')
          .doc(activityId)
          .get();
      
      if (doc.exists && context.mounted) {
        final activity = Activity.fromFirestore(doc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsScreen(activity: activity),
          ),
        );
      } else if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Activity details are no longer available.")),
         );
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error loading details: $e")),
         );
      }
    }
  }
}
