import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../features/community_activity/screens/community_activities_hub_screen.dart';
import '../features/community_activity/services/firestore_service.dart';
import '../features/community_activity/services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  // Static flag to ensure we only reset once per app session
  static bool _hasResetData = false;

  bool _isSigningIn = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _authError = null;
    });
    
    final user = await _firestoreService.signInAnonymously();
    
    if (mounted) {
      setState(() {
        _isSigningIn = false;
        if (user == null) {
          _authError = "⚠️ Guest Login Disabled. Please enable 'Anonymous' Sign-in in your Firebase Console (Authentication > Sign-in method).";
        }
      });
    }

    // Automatically reset and seed data ONCE when app starts if signed in
    if (user != null && !_hasResetData) {
      print("🚀 HomeScreen: Seeding default dummy activities...");
      // Seed around a default location (e.g. Bangalore center) 
      // instead of fetching current location to avoid intrusive prompt
      await _firestoreService.refreshActivitiesWithDummyData(
        baseLat: 12.9716, 
        baseLon: 77.5946
      );
      _hasResetData = true;
      print("✅ HomeScreen: Default seeding complete.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elderly Ease'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
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
                  "Welcome to Elderly Ease",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4D9689)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // --- Community Activities Button ---
                _buildMenuButton(
                  context, 
                  "Community Activities", 
                  Icons.groups, 
                  const Color(0xFF4D9689),
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityActivitiesHubScreen()))
                ),
                
                const SizedBox(height: 12),
                // Login Status Indicator
                _isSigningIn 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text("Guest Login in progress...", style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                              const SizedBox(width: 4),
                              Text("Logged in as Guest", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                            ],
                          );
                        }
                        
                        return Column(
                          children: [
                            if (_authError != null)
                              Text(_authError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: _signIn,
                              icon: const Icon(Icons.login, size: 18),
                              label: const Text("Retry Guest Login"),
                            ),
                          ],
                        );
                      },
                    ),


                const Spacer(),
                const Text("Version 1.0.1", style: TextStyle(color: Colors.grey)),
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
