import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with manual options
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDyZV7_NJURsYtOK311V4b13NG3uHv3tog",
      authDomain: "elderlyease-7be75.firebaseapp.com",
      projectId: "elderlyease-7be75",
      storageBucket: "elderlyease-7be75.appspot.com",
      messagingSenderId: "933473196",
      appId: "1:933473196:web:902488f3ce1317c333a809",
    ),
  );

  // Initialize persistent session
  await SessionService().init();
  
  runApp(const ConnectCircleApp());
}

class ConnectCircleApp extends StatelessWidget {
  const ConnectCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elderly Ease',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF008080), // Teal
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
          primary: const Color(0xFF006064), // Darker teal
          secondary: const Color(0xFF00838F),
          surface: const Color(0xFFE0F2F1), // Light teal background
        ),
        scaffoldBackgroundColor: const Color(0xFFE0F2F1), // Light teal
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF006064), fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Color(0xFF006064)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00838F), // Main teal
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
