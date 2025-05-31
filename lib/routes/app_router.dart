import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/planner/presentation/home_screen.dart';
import '../features/planner/presentation/profile_screen.dart';
import '../features/planner/presentation/tasks_screen.dart';
import '../features/auth/presentation/register_page.dart';

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
    final goingToAuth = state.matchedLocation == '/auth' || state.matchedLocation == '/register';

    if (session == null && !goingToAuth) return '/auth';
    if (session != null && goingToAuth) return '/';

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
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
  ],
);