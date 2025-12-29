import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'activity_details_screen.dart';
import 'package:intl/intl.dart';

class ActivityListScreen extends StatefulWidget {
  final String category;
  final Position? currentPosition;

  const ActivityListScreen({super.key, required this.category, this.currentPosition});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    if (_currentPosition != null) {
      _isLoading = false;
    } else {
      _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    debugPrint('Requesting location permission and fetching position...');
    Position? position = await _locationService.getCurrentLocation();
    
    if (mounted) {
      if (position == null) {
        debugPrint('Location fetch failed - showing dialog to user');
        // Show dialog asking user to enable location
        bool retry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange),
                SizedBox(width: 8),
                Text('Location Access Needed'),
              ],
            ),
            content: const Text(
              'To show nearby activities and calculate distances, this app needs:\n\n'
              '📍 Location permission\n'
              '🌍 GPS/Location services enabled\n\n'
              'Please enable both in your device settings.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ) ?? false;
        
        if (retry) {
          // Try again
          _getUserLocation();
          return;
        }
      } else {
        debugPrint('Location obtained: ${position.latitude}, ${position.longitude}');
      }
      
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Activities'),
      ),
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
                debugPrint('Fetched ${activities.length} activities for category: ${widget.category}');

                // Sorting by distance
                if (_currentPosition != null) {
                  debugPrint('User Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
                  
                  // Sort by distance (No proximity filter as requested)
                  activities.sort((a, b) {
                     double distA = _locationService.calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      a.latitude,
                      a.longitude,
                    );
                    double distB = _locationService.calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      b.latitude,
                      b.longitude,
                    );
                    return distA.compareTo(distB);
                  });
                } else {
                  debugPrint('Warning: Current position is null, showing all activities without distance sorting.');
                }
                
                if (activities.isEmpty) {
                   return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "No activities found in this category.", 
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.blueGrey)
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Please check back later or try another category.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                   );
                }

                return ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityCard(context, activity);
                  },
                );
              },
            ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity) {
    double? distance;
    if (_currentPosition != null) {
       distance = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        activity.latitude,
        activity.longitude,
      );
    }
    
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
             const SizedBox(height: 8),
            if (distance != null)
              Text(
                "${distance.toStringAsFixed(1)} km away",
                style:  TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailsScreen(
                  activity: activity,
                  distance: distance,
                ),
              ),
            );
          },
          child: const Text("View"),
        ),
      ),
    );
  }
}
