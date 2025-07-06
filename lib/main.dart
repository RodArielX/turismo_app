import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'home_page.dart'; // ✅ <--- IMPORTANTE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rywflcqqododltxrlkho.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5d2ZsY3Fxb2RvZGx0eHJsa2hvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE3NjczODQsImV4cCI6MjA2NzM0MzM4NH0.ncZoOlnOEP8BNEEneM04zHBuaziEG6pLvOnyGBDyz5w',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turismo Ciudadano',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthPage(),
        '/home': (_) => const HomePage(), // ✅ esta es la que hicimos bien
      },
    );
  }
}

