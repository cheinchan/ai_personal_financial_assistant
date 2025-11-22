import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Financial Assistant',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D9B8E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D9B8E),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(), // ← This checks auth automatically!
      debugShowCheckedModeBanner: false,
    );
  }
}