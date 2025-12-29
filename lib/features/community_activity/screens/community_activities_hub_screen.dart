import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'admin_add_activity_screen.dart';
import 'joined_activities_screen.dart';
import 'admin_participation_screen.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';

class CommunityActivitiesHubScreen extends StatelessWidget {
  const CommunityActivitiesHubScreen({super.key});

  Future<void> _handleBrowseActivities(BuildContext context) async {
    // 1. Show a custom "Ask" dialog EVERY TIME as requested
    final bool? shouldAllow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.purple),
            SizedBox(width: 8),
            Text("Share Location?"),
          ],
        ),
        content: const Text(
          "Elderly Ease would like to access your location to show you nearby activities. Would you like to allow this?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("NOT NOW", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("ALLOW"),
          ),
        ],
      ),
    );

    if (shouldAllow == true && context.mounted) {
      final locationService = LocationService();
      debugPrint('📍 Hub: Permission confirmed by elder. Fetching location...');
      
      final position = await locationService.getCurrentLocation();
      
      if (context.mounted) {
        if (position == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Location access is required to see distances. Please check your phone settings.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => CategoryScreen(currentPosition: position))
        );
      }
    } else if (shouldAllow == false && context.mounted) {
      // If elder says No, still let them browse but without location
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const CategoryScreen(currentPosition: null))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Activities'),
        backgroundColor: Colors.purple[50],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volunteer_activism, size: 80, color: Colors.purple),
                const SizedBox(height: 10),
                const Text(
                  "Community Activities Center",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // --- Elder Section ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Elder Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context, 
                  "Browse Activities", 
                  Icons.explore, 
                  Colors.purple,
                  () => _handleBrowseActivities(context)
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context, 
                  "My Joined Activities", 
                  Icons.event_available, 
                  Colors.deepPurple,
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
                const Spacer(),
              ],
            ),
          ),
        ),
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
