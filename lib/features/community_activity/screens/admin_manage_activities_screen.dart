import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class AdminManageActivitiesScreen extends StatefulWidget {
  const AdminManageActivitiesScreen({super.key});

  @override
  State<AdminManageActivitiesScreen> createState() => _AdminManageActivitiesScreenState();
}

class _AdminManageActivitiesScreenState extends State<AdminManageActivitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _deleteActivity(String id, String name) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Activity?"),
        content: Text("Are you sure you want to delete '$name'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("DELETE", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _firestoreService.deleteActivity(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting activity: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Activities'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('community_activities').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No activities found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final activity = Activity.fromFirestore(docs[index]);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(activity.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${activity.category.toUpperCase()} • ${DateFormat.yMMMd().format(activity.date)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteActivity(activity.id, activity.activityName),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Note: Need to import cloud_firestore for QuerySnapshot usage in the StreamBuilder
