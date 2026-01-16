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
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
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

              bool isAttended = status == 'attended';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Transform.scale(
                    scale: 1.5,
                    child: Checkbox(
                      value: isAttended,
                      activeColor: const Color(0xFF4D9689),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (bool? value) async {
                        if (value != null) {
                          String newStatus = value ? 'attended' : 'registered';
                          await FirestoreService().updateActivityStatus(activityId, newStatus);
                        }
                      },
                    ),
                  ),
                  title: Text(
                    data['activityName'] ?? 'Unnamed Activity',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("${data['date']} at ${data['time']}", style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        isAttended ? "✅ Participated" : "⏳ Registered (Not yet ticked)",
                        style: TextStyle(
                          color: isAttended ? Colors.green : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () => _navigateToDetails(context, activityId),
                        tooltip: 'View Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                        onPressed: () => _confirmUnregister(context, activityId, data['activityName'] ?? 'this activity'),
                        tooltip: 'Remove',
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
