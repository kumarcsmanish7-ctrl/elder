import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import 'activity_details_screen.dart';
import 'package:intl/intl.dart';

class ActivityListScreen extends StatefulWidget {
  final String category;
  // Position is no longer used for distances as requested

  const ActivityListScreen({super.key, required this.category});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false; // Set to false since we aren't fetching location anymore

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Activities'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Activity>>(
              stream: _firestoreService.getActivities(widget.category),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Firestore Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Activity> activities = snapshot.data ?? [];
                debugPrint('🔍 Fetched ${activities.length} activities for ${widget.category}: ${activities.map((a) => a.activityName).toList()}');

                if (activities.isEmpty) return _buildNoActivitiesWidget();
                
                return ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    return _buildActivityCard(context, activities[index]);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNoActivitiesWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No activities found in this category.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          activity.activityName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(activity.address, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                 const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                 const SizedBox(width: 4),
                 Text(DateFormat.yMMMd().add_jm().format(activity.date)),
              ],
            ),
            // Removed red locator coordinates row
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailsScreen(
                  activity: activity,
                ),
              ),
            );
          },
          child: const Text("View"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4D9689),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
