import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/community_activity/screens/elder_hub_screen.dart';
import 'features/community_activity/services/firestore_service.dart';

// ELDER SECTION ENTRY POINT
// This file is for the Elder app section
// Team lead will add their own login before ElderHubScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Enable offline persistence for auth state
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print("✅ Firebase initialized with persistent auth");
  } catch (e) {
    print("Firebase initialization failed: $e");
  }

  // Sign in anonymously and seed data for demo
  await _initializeElderApp();

  runApp(const ElderApp());
}

Future<void> _initializeElderApp() async {
  final firestoreService = FirestoreService();
  
  try {
    // Check if there's already a signed-in user
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      // Only sign in anonymously if no user exists
      print("🔐 Elder App: No user found, signing in anonymously...");
      currentUser = await firestoreService.signInAnonymously();
    } else {
      print("✅ Elder App: Existing user found: ${currentUser.uid}");
    }
    
    if (currentUser != null) {
      print("🚀 Elder App: Seeding activities if needed...");
      await firestoreService.refreshActivitiesWithDummyData(
        baseLat: 12.9716, 
        baseLon: 77.5946
      );
      print("✅ Elder App initialized.");
    }
  } catch (e) {
    print("⚠️ Initialization warning: $e");
  }
}

class ElderApp extends StatelessWidget {
  const ElderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elderly Ease - Elder',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      // TODO: Team lead should add login screen here
      // For now, goes directly to Elder Hub
      home: const ElderHubScreen(),
    );
  }
}
