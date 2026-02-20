import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const SolarDryingApp());
}

class SolarDryingApp extends StatelessWidget {
  const SolarDryingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Solar Drying',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF13B546),
      ),
      home: const SplashScreen(),
    );
  }
}