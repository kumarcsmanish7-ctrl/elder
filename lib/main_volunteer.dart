import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'features/community_activity/screens/volunteer_login_screen.dart';
import 'features/community_activity/services/firestore_service.dart';

// VOLUNTEER SECTION ENTRY POINT
// This is your section - Volunteer Login → Volunteer Hub

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  // Seed data for volunteers to manage
  await _initializeVolunteerApp();

  runApp(const VolunteerApp());
}

Future<void> _initializeVolunteerApp() async {
  final firestoreService = FirestoreService();
  
  try {
    print("🚀 Volunteer App: Seeding activities...");
    // Only seed if database is empty
    await firestoreService.refreshActivitiesWithDummyData(
      baseLat: 12.9716, 
      baseLon: 77.5946
    );
    print("✅ Volunteer App initialized.");
  } catch (e) {
    print("⚠️ Initialization warning: $e");
  }
}

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elderly Ease - Volunteer',
      theme: ThemeData(
        primaryColor: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const VolunteerLoginScreen(),
    );
  }
}
