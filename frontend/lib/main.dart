import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FluwApp());
}

class FluwApp extends StatelessWidget {
  const FluwApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluw',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676),
          primary: const Color(0xFF141414),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
