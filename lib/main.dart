import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'Daily Reminder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4DB6AC), // Light teal (1 shade lighter)
            surface: const Color(0xFFF5F5F5), // Soft light background
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4DB6AC), // Light teal
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
          ),
          // Elder-friendly text theme
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
            displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
            displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.black87),
            titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
            titleSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
            bodyLarge: TextStyle(fontSize: 22, color: Colors.black87),
            bodyMedium: TextStyle(fontSize: 20, color: Colors.black87),
            bodySmall: TextStyle(fontSize: 18, color: Colors.black87),
            labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
