import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminParticipationScreen extends StatelessWidget {
  const AdminParticipationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin: Activity Participation'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('joinedActivities').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No participation data available yet.'));
          }

          // Grouping by activity
          Map<String, List<DocumentSnapshot>> grouped = {};
          for (var doc in docs) {
            String activityName = doc['activityName'] ?? 'Unknown Activity';
            if (!grouped.containsKey(activityName)) {
              grouped[activityName] = [];
            }
            grouped[activityName]!.add(doc);
          }

          return ListView.builder(
            itemCount: grouped.keys.length,
            itemBuilder: (context, index) {
              String activityName = grouped.keys.elementAt(index);
              List<DocumentSnapshot> activityDocs = grouped[activityName]!;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ExpansionTile(
                  title: Text(activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${activityDocs.length} Total Registrations"),
                  children: activityDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'registered';
                    String date = data['date'] ?? '';
                    
                    // We can't easily get the user name here without another query, 
                    // but we can show the User ID or status details.
                    String userId = doc.reference.parent.parent?.id ?? 'Unknown User';

                    return ListTile(
                      leading: Icon(
                        status == 'attended' ? Icons.check_circle : 
                        status == 'not_attended' ? Icons.cancel : Icons.info_outline,
                        color: status == 'attended' ? Colors.green : 
                               status == 'not_attended' ? Colors.red : const Color(0xFF4D9689),
                      ),
                      title: Text("User ID: ${userId.substring(0, 8)}..."),
                      subtitle: Text("Status: ${status.toUpperCase()} | Date: $date"),
                      trailing: Text(DateFormat.yMd().add_jm().format(
                        (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now()
                      )),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
