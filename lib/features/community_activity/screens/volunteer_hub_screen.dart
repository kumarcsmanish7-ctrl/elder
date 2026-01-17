import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_add_activity_screen.dart';
import 'admin_participation_screen.dart';
import 'admin_manage_activities_screen.dart';
import 'volunteer_login_screen.dart';

class VolunteerHubScreen extends StatelessWidget {
  const VolunteerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Center'),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        actions: [
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.volunteer_activism,
                size: 80,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 10),
              const Text(
                "Volunteer Management",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Organize and track community activities",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              _buildMenuButton(
                context,
                "Add New Activity",
                Icons.add_location_alt,
                Colors.blueGrey,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminAddActivityScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                "Track Participation",
                Icons.assignment_turned_in,
                Colors.blueGrey[700]!,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminParticipationScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                "Manage Activities",
                Icons.delete_sweep,
                Colors.redAccent,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminManageActivitiesScreen()),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();
                
                // Navigate back to login screen
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const VolunteerLoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
