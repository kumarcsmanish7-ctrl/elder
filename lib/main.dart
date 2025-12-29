import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: Ensure you have configured Firebase and updated firebase_options.dart
  // If you haven't, running this will fail. 
  // For now, we wrap in try-catch to allow UI to run if config is missing (for demo purposes)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization failed: $e. Did you setup firebase_options.dart?");
  }

  runApp(const ElderlyApp());
}

class ElderlyApp extends StatelessWidget {
  const ElderlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elderly App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

