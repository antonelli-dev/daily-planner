import 'package:flutter/material.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  final String? workspaceId; // Add workspaceId parameter

  const HomeScreen({
    super.key,
    this.workspaceId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Fix: Use getter instead of const list since we need to pass workspaceId
  List<Widget> get _screens => [
    TasksScreen(workspaceId: widget.workspaceId), // Pass workspaceId when we implement EnhancedTasksScreen
    ProfileScreen(), // Keep current profile screen for now
  ];

  // Fix: Match the number of titles with screens
  final List<String> _titles = [
    'Tasks',
    'Profile',
  ];

  // Fix: Match the number of nav items with screens
  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.checklist_rtl_rounded,
      label: 'Tareas',
    ),
    NavItem(
      icon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            // Workspace selector button
            if (widget.workspaceId != null)
              GestureDetector(
                onTap: () => context.go('/workspaces'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspaces,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Workspace',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            // Settings button for workspace
            if (widget.workspaceId != null)
              IconButton(
                onPressed: () => context.push('/workspace/${widget.workspaceId}/settings'),
                icon: Icon(
                  Icons.settings,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.shade300,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Expanded(
                  child: _buildNavItem(
                    icon: item.icon,
                    label: item.label,
                    index: index,
                    isSelected: _currentIndex == index,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(height: 1),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for navigation items
class NavItem {
  final IconData icon;
  final String label;

  NavItem({
    required this.icon,
    required this.label,
  });
}