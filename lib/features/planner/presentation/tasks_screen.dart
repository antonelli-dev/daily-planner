// lib/features/planner/presentation/tasks_screen.dart
// Updated to use real schedule data instead of demo data

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../schedule/domain/entities/schedule.entity.dart';
import '../../schedule/domain/usecases/get_schedules.usecase.dart';
import '../../schedule/domain/usecases/complete_schedule.usecase.dart';
import '../../../core/shared/widgets/loading_widget.dart';
import '../../../core/shared/widgets/error_widget.dart';

class TasksScreen extends StatefulWidget {
  final String? workspaceId;

  const TasksScreen({
    super.key,
    this.workspaceId,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Schedule> _todaySchedules = [];
  List<Schedule> _upcomingSchedules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (widget.workspaceId == null) {
      // If no workspace selected, show empty state
      setState(() {
        _loading = false;
        _todaySchedules = [];
        _upcomingSchedules = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final getSchedulesUseCase = GetIt.I<GetSchedulesUseCase>();

      // Load today's schedules
      final todaySchedules = await getSchedulesUseCase.getTodaySchedules(widget.workspaceId!);

      // Load upcoming schedules (next 7 days)
      final upcomingSchedules = await getSchedulesUseCase.getSchedulesForWeek(
        widget.workspaceId!,
        DateTime.now().add(const Duration(days: 1)),
      );

      setState(() {
        _todaySchedules = todaySchedules;
        _upcomingSchedules = upcomingSchedules.take(5).toList(); // Limit to 5 for overview
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _completeSchedule(Schedule schedule) async {
    try {
      final completeScheduleUseCase = GetIt.I<CompleteScheduleUseCase>();
      await completeScheduleUseCase(widget.workspaceId!, schedule.id);

      _showSnackBar('Schedule marked as completed!', isSuccess: true);
      _loadSchedules(); // Refresh data
    } catch (e) {
      _showSnackBar('Error completing schedule: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : (isSuccess ? Icons.check_circle : Icons.info_outline),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : Colors.blue),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ?? 'Usuario';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSchedules,
          child: _buildBody(userName),
        ),
      ),
    );
  }

  Widget _buildBody(String userName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Header with user info and workspace info
          _buildUserInfo(userName),
          const SizedBox(height: 24),

          // Workspace info (if available)
          if (widget.workspaceId != null) ...[
            _buildWorkspaceInfo(),
            const SizedBox(height: 24),
          ],

          // Today's progress card with real data
          _buildProgressCard(),
          const SizedBox(height: 32),

          // Today's schedules section
          if (_loading)
            const LoadingWidget(message: 'Loading schedules...')
          else if (_error != null)
            CustomErrorWidget.generic(
              message: _error!,
              onRetry: _loadSchedules,
            )
          else if (widget.workspaceId == null)
              _buildNoWorkspaceState()
            else ...[
                // Today's schedules
                if (_todaySchedules.isNotEmpty) ...[
                  _buildSectionTitle('Today\'s Schedule', _todaySchedules.length),
                  const SizedBox(height: 16),
                  ..._todaySchedules.map(_buildScheduleCard),
                  const SizedBox(height: 32),
                ],

                // Upcoming schedules
                if (_upcomingSchedules.isNotEmpty) ...[
                  _buildSectionTitle('Upcoming', _upcomingSchedules.length),
                  const SizedBox(height: 16),
                  ..._upcomingSchedules.map(_buildScheduleCard),
                  const SizedBox(height: 16),
                  _buildViewAllButton(),
                  const SizedBox(height: 32),
                ],

                // Empty state if no schedules
                if (_todaySchedules.isEmpty && _upcomingSchedules.isEmpty)
                  _buildEmptySchedulesState(),

                // Legacy task groups (keep for now if you want to show them alongside schedules)
                _buildSectionTitle('Task Groups', 4),
                const SizedBox(height: 16),
                _buildTaskGroups(),
              ],
        ],
      ),
    );
  }

  Widget _buildUserInfo(String userName) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade400,
            borderRadius: BorderRadius.circular(25),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (widget.workspaceId != null) ...[
          // Calendar view button
          IconButton(
            onPressed: () => context.push('/workspace/${widget.workspaceId}/calendar'),
            icon: Icon(
              Icons.calendar_today,
              color: Colors.grey.shade700,
              size: 20,
            ),
            tooltip: 'Calendar View',
          ),
          // Add schedule button
          IconButton(
            onPressed: () async {
              await context.push('/workspace/${widget.workspaceId}/create-schedule');
              _loadSchedules();
            },
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.shade400,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
            tooltip: 'Add Schedule',
          ),
        ],
      ],
    );
  }

  Widget _buildWorkspaceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspaces,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Workspace: ${widget.workspaceId!.substring(0, 8)}...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    // Use real schedule data for progress calculation
    final completedToday = _todaySchedules.where((s) => s.isCompleted).length;
    final totalToday = _todaySchedules.length;
    final progress = totalToday > 0 ? completedToday / totalToday : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workspaceId != null
                      ? (totalToday > 0
                      ? 'Today\'s schedule\n${completedToday == totalToday ? 'completed!' : 'in progress'}'
                      : 'No schedules\nfor today')
                      : 'Select workspace\nto view schedules',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.workspaceId != null
                      ? () => context.push('/workspace/${widget.workspaceId}/calendar')
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.workspaceId != null ? 'View Calendar' : 'Select Workspace',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(Schedule schedule) {
    final color = _parseColor(schedule.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: schedule.isCompleted
                ? Border.all(color: Colors.green, width: 2)
                : null,
          ),
          child: Icon(
            _getIconData(schedule.icon),
            color: schedule.isCompleted ? Colors.green : color,
            size: 24,
          ),
        ),
        title: Text(
          schedule.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            decoration: schedule.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  schedule.timeRange,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (schedule.isAssigned) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    schedule.assignedToName ?? 'Assigned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            if (schedule.description != null && schedule.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                schedule.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            _buildScheduleStatus(schedule),
          ],
        ),
        trailing: schedule.isCompleted
            ? Icon(Icons.check_circle, color: Colors.green.shade400)
            : IconButton(
          onPressed: () => _completeSchedule(schedule),
          icon: Icon(
            Icons.check_circle_outline,
            color: Colors.grey.shade400,
          ),
          tooltip: 'Mark as completed',
        ),
        onTap: () => context.push('/workspace/${widget.workspaceId}/schedule/${schedule.id}/edit'),
      ),
    );
  }

  Widget _buildScheduleStatus(Schedule schedule) {
    if (schedule.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Completed',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
      );
    }

    if (schedule.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Overdue',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
      );
    }

    if (schedule.isInProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'In Progress',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Upcoming',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Container(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/workspace/${widget.workspaceId}/calendar'),
        icon: const Icon(Icons.calendar_view_month),
        label: const Text('View All in Calendar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.purple.shade400,
          side: BorderSide(color: Colors.purple.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildNoWorkspaceState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.workspaces_outlined,
                size: 40,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No workspace selected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a workspace to view and manage your schedules',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/workspaces'),
              child: const Text('Select Workspace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySchedulesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.schedule,
                size: 40,
                color: Colors.purple.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No schedules yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first schedule to start organizing your day',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/workspace/${widget.workspaceId}/create-schedule'),
              icon: const Icon(Icons.add),
              label: const Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  // Keep your existing demo task groups for now (can be removed later)
  Widget _buildTaskGroups() {
    return Column(
      children: [
        _buildTaskGroupItem(
          'Office Project',
          '23 Tasks',
          Colors.pink.shade100,
          Colors.pink.shade400,
          Icons.work_outline,
          0.70,
        ),
        const SizedBox(height: 12),
        _buildTaskGroupItem(
          'Personal Project',
          '30 Tasks',
          Colors.purple.shade100,
          Colors.purple.shade400,
          Icons.person_outline,
          0.52,
        ),
        const SizedBox(height: 12),
        _buildTaskGroupItem(
          'Daily Study',
          '30 Tasks',
          Colors.orange.shade100,
          Colors.orange.shade400,
          Icons.school_outlined,
          0.87,
        ),
      ],
    );
  }

  Widget _buildTaskGroupItem(String title, String subtitle, Color bgColor, Color accentColor, IconData icon, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.purple.shade400;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'work':
        return Icons.work_outline;
      case 'meeting':
        return Icons.groups_outlined;
      case 'call':
        return Icons.phone_outlined;
      case 'exercise':
        return Icons.fitness_center_outlined;
      case 'study':
        return Icons.school_outlined;
      case 'personal':
        return Icons.person_outline;
      case 'travel':
        return Icons.flight_outlined;
      case 'health':
        return Icons.local_hospital_outlined;
      default:
        return Icons.event_outlined;
    }
  }
}