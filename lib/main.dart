import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
