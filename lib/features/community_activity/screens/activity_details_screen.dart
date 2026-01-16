import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../services/reminder_service.dart';
import '../widgets/feedback_dialog.dart';
import '../models/activity_feedback.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Activity activity;
  const ActivityDetailsScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ReminderService _reminderService = ReminderService();
  bool _isJoined = false;
  String? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
  }

  Future<void> _checkJoinStatus() async {
    try {
      final user = _firestoreService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('joinedActivities')
            .doc(widget.activity.id)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 5));
        
        if (doc.exists && mounted) {
           setState(() {
             _isJoined = true;
             _status = doc.data()?['status'];
           });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Join status check timed out or failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPast = widget.activity.date.isBefore(DateTime.now());
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activity Details'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(widget.activity.latitude, widget.activity.longitude),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.elderly_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(widget.activity.latitude, widget.activity.longitude),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF4D9689),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.activity.activityName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 32),
                      _buildInfoRow(Icons.calendar_today, "Date & Time", 
                        DateFormat.yMMMMd().add_jm().format(widget.activity.date)),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.location_on, "Address", widget.activity.address),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.person, "Organizer", 
                        "${widget.activity.organizerName}\n${widget.activity.organizerContact}"),
                      const Divider(height: 32),
                      const Text(
                        "Description",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.activity.shortDescription,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      const Text("Recommended for You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Activity>>(
                        stream: _firestoreService.getRecommendations(widget.activity.category, widget.activity.id),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text("No similar activities found yet.", style: TextStyle(color: Colors.grey, fontSize: 14));
                          }
                          return Column(
                            children: snapshot.data!.map((rec) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.event, color: Color(0xFF4D9689)),
                                title: Text(rec.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(DateFormat.yMMMd().format(rec.date)),
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => ActivityDetailsScreen(activity: rec))
                                  );
                                },
                              ),
                            )).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
      bottomNavigationBar: _isLoading 
        ? null 
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isJoined && isPast)
                    _buildChecklistSection()
                  else if (_isJoined)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D9689).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4D9689)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF4D9689)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Registered Successfully!", 
                                  style: TextStyle(color: Color(0xFF4D9689), fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Status: Joining logic complete ✅", 
                                  style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _unregisterActivity(context),
                            child: const Text("REMOVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  else if (isPast)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showFeedbackDialog(context),
                        icon: const Icon(Icons.rate_review),
                        label: const Text("Give Feedback"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _joinActivity(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4D9689),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        icon: const Icon(Icons.event_available, size: 24),
                        label: const Text("Join Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildChecklistSection() {
    bool isAttended = _status == 'attended';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: CheckboxListTile(
        title: const Text("I participated in this activity", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(isAttended ? "Status: Participated ✅" : "Tap the box if you attended"),
        value: isAttended,
        activeColor: const Color(0xFF4D9689),
        onChanged: (bool? value) {
          if (value != null) {
            _updateAttendance(value ? 'attended' : 'registered');
          }
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _updateAttendance(String status) async {
    try {
      final user = _firestoreService.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('joinedActivities')
            .doc(widget.activity.id)
            .update({'status': status});
        
        setState(() => _status = status);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $status')),
          );
        }
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF4D9689)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) async {
    final feedback = await showDialog<ActivityFeedback>(
      context: context,
      builder: (context) => FeedbackDialog(activityId: widget.activity.id),
    );

    if (feedback != null) {
      try {
        await _firestoreService.submitFeedback(feedback);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted successfully! Thank you.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting feedback: $e')));
        }
      }
    }
  }

  void _joinActivity(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Join"),
        content: const Text("Do you want to join this activity? You will receive notifications with sound 1 day and 1 hour before."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    ) ?? false;

    if (confirm) {
        setState(() {
          _isJoined = true;
          _status = 'registered';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Joined! Scheduling reminders with sound...'),
            backgroundColor: Color(0xFF4D9689),
            duration: Duration(seconds: 2),
          ),
        );

        try {
            await _reminderService.init();
            DateTime oneDayBefore = widget.activity.date.subtract(const Duration(days: 1));
            DateTime oneHourBefore = widget.activity.date.subtract(const Duration(hours: 1));

            await _reminderService.scheduleReminder(
              widget.activity.id.hashCode + 1,
              "Activity Tomorrow: ${widget.activity.activityName}",
              "Starts tomorrow at ${widget.activity.address}",
              oneDayBefore,
            );
            
            await _reminderService.scheduleReminder(
              widget.activity.id.hashCode,
              "Reminder: ${widget.activity.activityName}",
              "Starts in 1 hour at ${widget.activity.address}",
              oneHourBefore,
            );

            _firestoreService.joinActivity(widget.activity).catchError((e) {
               debugPrint("⚠️ Background Firestore sync failed: $e");
            });

        } catch (e) {
            debugPrint('❌ Reminder scheduling issues: $e');
        }
    }
  }

  void _unregisterActivity(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Registration?"),
        content: const Text("Are you sure you want to unregister from this activity? Your reminders will be cancelled."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Back")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Unregister", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
        try {
           await _firestoreService.unregisterActivity(widget.activity.id);
           setState(() {
             _isJoined = false;
             _status = null;
           });
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('🗑️ Registration cancelled successfully.')),
             );
           }
        } catch(e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unregister: $e')));
           }
        }
    }
  }
}
