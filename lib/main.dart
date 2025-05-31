// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';
import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://bvsunayzlwndtdgecmxs.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2c3VuYXl6bHduZHRkZ2VjbXhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE0NTc2MjQsImV4cCI6MjA1NzAzMzYyNH0.hyWVM1b1SV0zJqdfgl6caQMksQW2xlT-To7zp8gonpI'
  );

  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Daily Planner',
      theme: ThemeData.dark(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
