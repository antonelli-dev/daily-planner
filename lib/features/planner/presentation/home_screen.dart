import 'package:flutter/material.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TasksScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Tareas',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.checklist_rtl_rounded,
                    label: 'Tareas',
                    index: 0,
                    isSelected: _currentIndex == 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Perfil',
                    index: 1,
                    isSelected: _currentIndex == 1,
                  ),
                ),
              ],
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