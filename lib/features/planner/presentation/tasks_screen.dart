import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Esta es una pantalla de ejemplo. Luego se conecta a Supabase.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.checklist, size: 64),
          SizedBox(height: 16),
          Text(
            'Aquí irán tus tareas',
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
