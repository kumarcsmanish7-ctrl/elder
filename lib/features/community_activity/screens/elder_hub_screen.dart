import 'package:flutter/material.dart';
import 'category_screen.dart';
import 'joined_activities_screen.dart';

class ElderHubScreen extends StatelessWidget {
  const ElderHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elder Activities'),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                size: 80,
                color: Color(0xFF4D9689),
              ),
              const SizedBox(height: 10),
              const Text(
                "Elder Activities Center",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4D9689),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Find and join activities near you",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              _buildMenuButton(
                context,
                "Browse Activities",
                Icons.explore,
                const Color(0xFF4D9689),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                "Track Your Participation",
                Icons.event_available,
                const Color(0xFF3B7369),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JoinedActivitiesScreen()),
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
}
