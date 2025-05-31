import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/planner/presentation/home_screen.dart';
import '../features/planner/presentation/profile_screen.dart';
import '../features/planner/presentation/tasks_screen.dart';

// Create a ChangeNotifier for auth state
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      notifyListeners();
    });
  }
}

final authChangeNotifier = AuthChangeNotifier();

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authChangeNotifier,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggingIn = state.matchedLocation == '/auth';

    // If no session and not on auth page, redirect to auth
    if (session == null && !loggingIn) return '/auth';

    // If has session and on auth page, redirect to home
    if (session != null && loggingIn) return '/';

    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const TasksScreen(),
    ),
  ],
);