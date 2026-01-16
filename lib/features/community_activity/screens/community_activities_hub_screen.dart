import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'admin_add_activity_screen.dart';
import 'joined_activities_screen.dart';
import 'admin_participation_screen.dart';
import 'admin_manage_activities_screen.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';

class CommunityActivitiesHubScreen extends StatefulWidget {
  const CommunityActivitiesHubScreen({super.key});

  @override
  State<CommunityActivitiesHubScreen> createState() => _CommunityActivitiesHubScreenState();
}

class _CommunityActivitiesHubScreenState extends State<CommunityActivitiesHubScreen> {
  bool _isLocating = false;

  void _handleBrowseActivities(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Activities'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volunteer_activism, size: 80, color: Color(0xFF4D9689)),
                    const SizedBox(height: 10),
                    const Text(
                      "Community Activities Center",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4D9689)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    
                    // --- Elder Section ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Elder Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4D9689))),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context, 
                      "Browse Activities", 
                      Icons.explore, 
                      const Color(0xFF4D9689),
                      () => _handleBrowseActivities(context)
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context, 
                      "Track Your Participation", 
                      Icons.event_available, 
                      const Color(0xFF3B7369),
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JoinedActivitiesScreen()))
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // --- Admin Section ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Admin / Caretaker Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context, 
                      "Add New Activity", 
                      Icons.add_location_alt, 
                      Colors.blueGrey,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddActivityScreen()))
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context, 
                      "Track Participation", 
                      Icons.assignment_turned_in, 
                      Colors.blueGrey[700]!,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminParticipationScreen()))
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context, 
                      "Manage Activities (Delete)", 
                      Icons.delete_sweep, 
                      Colors.redAccent,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageActivitiesScreen()))
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          // Removed locating overlay
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(icon, size: 24),
        label: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
