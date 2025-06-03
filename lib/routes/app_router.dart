import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/planner/presentation/home_screen.dart';
import '../features/planner/presentation/profile_screen.dart';
import '../features/planner/presentation/tasks_screen.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/workspace/presentation/workspace_selection_screen.dart';
import '../features/workspace/presentation/create_workspace_screen.dart';
import '../features/workspace/presentation/workspace_settings_screen.dart';
// TODO: Import schedule screens when implemented
// import '../features/schedule/presentation/enhanced_tasks_screen.dart';
// import '../features/schedule/presentation/create_task_screen.dart';

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
    // Auth routes
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // Main app routes
    GoRoute(
      path: '/',
      builder: (context, state) => const WorkspaceSelectionScreen(),
    ),

    // Workspace routes
    GoRoute(
      path: '/workspaces',
      builder: (context, state) => const WorkspaceSelectionScreen(),
    ),
    GoRoute(
      path: '/create-workspace',
      builder: (context, state) => const CreateWorkspaceScreen(),
    ),
    GoRoute(
      path: '/workspace/:id',
      builder: (context, state) {
        final workspaceId = state.pathParameters['id']!;
        return HomeScreen(workspaceId: workspaceId); // Update HomeScreen to accept workspaceId
      },
    ),
    GoRoute(
      path: '/workspace/:id/settings',
      builder: (context, state) {
        final workspaceId = state.pathParameters['id']!;
        return WorkspaceSettingsScreen(workspaceId: workspaceId);
      },
    ),

    // Legacy routes (for current demo screens)
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const TasksScreen(),
    ),

    // TODO: Add schedule routes when implemented
    // GoRoute(
    //   path: '/workspace/:workspaceId/create-task',
    //   builder: (context, state) {
    //     final workspaceId = state.pathParameters['workspaceId']!;
    //     return CreateTaskScreen(workspaceId: workspaceId);
    //   },
    // ),
  ],
);