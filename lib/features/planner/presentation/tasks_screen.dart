// lib/features/planner/presentation/tasks_screen.dart
// Fixed version with proper state management and filtering

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../schedule/domain/entities/schedule.entity.dart';
import '../../schedule/domain/usecases/get_schedules.usecase.dart';
import '../../schedule/domain/usecases/complete_schedule.usecase.dart';
import '../../../core/shared/widgets/loading_widget.dart';
import '../../../core/shared/widgets/error_widget.dart';

enum ScheduleFilter { all, active, completed, overdue, today, upcoming }

class TasksScreen extends StatefulWidget {
  final String? workspaceId;

  const TasksScreen({
    super.key,
    this.workspaceId,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with AutomaticKeepAliveClientMixin {
  List<Schedule> _allSchedules = [];
  List<Schedule> _filteredSchedules = [];
  bool _loading = true;
  String? _error;

  // Filter state
  ScheduleFilter _currentFilter = ScheduleFilter.all;
  SchedulePriority? _priorityFilter;
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void didUpdateWidget(TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if workspace changed
    if (oldWidget.workspaceId != widget.workspaceId) {
      _loadSchedules();
    }
  }

  Future<void> _loadSchedules() async {
    if (widget.workspaceId == null) {
      setState(() {
        _loading = false;
        _allSchedules = [];
        _filteredSchedules = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final getSchedulesUseCase = GetIt.I<GetSchedulesUseCase>();

      // Load a broader range for better filtering
      final now = DateTime.now();
      final List<Schedule> allSchedules = [];

      // Load past week, today, and next month
      for (var i = -7; i <= 30; i++) {
        final date = now.add(Duration(days: i));
        try {
          final daySchedules = await getSchedulesUseCase(widget.workspaceId!, date: date);
          allSchedules.addAll(daySchedules);
        } catch (e) {
          // Continue loading other days if one fails
          print('Error loading schedules for $date: $e');
        }
      }

      if (mounted) {
        setState(() {
          _allSchedules = allSchedules;
          _filteredSchedules = _applyFilters(allSchedules);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<Schedule> _applyFilters(List<Schedule> schedules) {
    var filtered = List<Schedule>.from(schedules);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        return schedule.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (schedule.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply status filter
    switch (_currentFilter) {
      case ScheduleFilter.all:
        break;
      case ScheduleFilter.active:
        filtered = filtered.where((s) => s.isInProgress).toList();
        break;
      case ScheduleFilter.completed:
        filtered = filtered.where((s) => s.isCompleted).toList();
        break;
      case ScheduleFilter.overdue:
        filtered = filtered.where((s) => s.isOverdue).toList();
        break;
      case ScheduleFilter.today:
        filtered = filtered.where((s) => s.isToday).toList();
        break;
      case ScheduleFilter.upcoming:
        filtered = filtered.where((s) => s.isUpcoming).toList();
        break;
    }

    // Apply priority filter
    if (_priorityFilter != null) {
      filtered = filtered.where((s) => s.priority == _priorityFilter).toList();
    }

    // Sort by date and priority
    filtered.sort((a, b) {
      // Completed items go to bottom
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // Then by priority (high first)
      const priorityOrder = {
        SchedulePriority.high: 3,
        SchedulePriority.medium: 2,
        SchedulePriority.low: 1,
      };
      final priorityComparison = (priorityOrder[b.priority] ?? 0) - (priorityOrder[a.priority] ?? 0);
      if (priorityComparison != 0) return priorityComparison;

      // Finally by start time
      return a.startTime.compareTo(b.startTime);
    });

    return filtered;
  }

  void _updateFilters() {
    setState(() {
      _filteredSchedules = _applyFilters(_allSchedules);
    });
  }

  Future<void> _completeSchedule(Schedule schedule) async {
    try {
      final completeScheduleUseCase = GetIt.I<CompleteScheduleUseCase>();
      await completeScheduleUseCase(widget.workspaceId!, schedule.id);

      _showSnackBar('Schedule marked as completed!', isSuccess: true);

      // Update the local state immediately for better UX
      if (mounted) {
        setState(() {
          final index = _allSchedules.indexWhere((s) => s.id == schedule.id);
          if (index != -1) {
            _allSchedules[index] = schedule.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
            );
            _filteredSchedules = _applyFilters(_allSchedules);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error completing schedule: ${e.toString()}', isError: true);
    }
  }

  Future<void> _navigateToEditSchedule(Schedule schedule) async {
    final result = await context.push('/workspace/${widget.workspaceId}/schedule/${schedule.id}/edit');

    // Handle the result properly
    if (result != null && mounted) {
      if (result == 'deleted') {
        _showSnackBar('Schedule deleted successfully!', isSuccess: true);
        // Remove from local state
        setState(() {
          _allSchedules.removeWhere((s) => s.id == schedule.id);
          _filteredSchedules = _applyFilters(_allSchedules);
        });
      } else if (result is Schedule) {
        _showSnackBar('Schedule updated successfully!', isSuccess: true);
        // Update local state with the updated schedule
        setState(() {
          final index = _allSchedules.indexWhere((s) => s.id == schedule.id);
          if (index != -1) {
            _allSchedules[index] = result;
            _filteredSchedules = _applyFilters(_allSchedules);
          }
        });
      }
      // Refresh to ensure we have the latest data
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadSchedules();
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (mounted) {
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
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
    return Column(
      children: [
        // Search and filter header
        _buildSearchAndFilterHeader(),

        // Active filters chips
        if (_currentFilter != ScheduleFilter.all || _priorityFilter != null || _searchQuery.isNotEmpty)
          _buildActiveFilters(),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header with user info
                _buildUserInfo(userName),
                const SizedBox(height: 24),

                // Workspace info
                if (widget.workspaceId != null) ...[
                  _buildWorkspaceInfo(),
                  const SizedBox(height: 24),
                ],

                // Progress card
                _buildProgressCard(),
                const SizedBox(height: 32),

                // Schedules section
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
                      // Schedules list
                      if (_filteredSchedules.isNotEmpty) ...[
                        _buildSectionTitle('Schedules', _filteredSchedules.length),
                        const SizedBox(height: 16),
                        ..._filteredSchedules.map(_buildScheduleCard),
                        const SizedBox(height: 32),
                      ],

                      // No results state
                      if (_filteredSchedules.isEmpty && _allSchedules.isNotEmpty)
                        _buildNoResultsState(),

                      // Empty state
                      if (_allSchedules.isEmpty)
                        _buildEmptySchedulesState(),
                    ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _updateFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search schedules...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              tooltip: 'Filters',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_currentFilter != ScheduleFilter.all)
            _buildFilterChip(
              _getFilterName(_currentFilter),
                  () {
                setState(() {
                  _currentFilter = ScheduleFilter.all;
                });
                _updateFilters();
              },
            ),
          if (_priorityFilter != null)
            _buildFilterChip(
              '${_priorityFilter!.displayName} Priority',
                  () {
                setState(() {
                  _priorityFilter = null;
                });
                _updateFilters();
              },
            ),
          if (_searchQuery.isNotEmpty)
            _buildFilterChip(
              'Search: "${_searchQuery.length > 10 ? '${_searchQuery.substring(0, 10)}...' : _searchQuery}"',
                  () {
                setState(() {
                  _searchQuery = '';
                });
                _updateFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Colors.purple.shade100,
      labelStyle: TextStyle(color: Colors.purple.shade700, fontSize: 12),
      deleteIconColor: Colors.purple.shade700,
    );
  }

  String _getFilterName(ScheduleFilter filter) {
    switch (filter) {
      case ScheduleFilter.all:
        return 'All';
      case ScheduleFilter.active:
        return 'Active';
      case ScheduleFilter.completed:
        return 'Completed';
      case ScheduleFilter.overdue:
        return 'Overdue';
      case ScheduleFilter.today:
        return 'Today';
      case ScheduleFilter.upcoming:
        return 'Upcoming';
    }
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Filter Schedules',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Status filter
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ScheduleFilter.values.map((filter) {
              final isSelected = _currentFilter == filter;
              return FilterChip(
                label: Text(_getFilterName(filter)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = filter;
                  });
                  _updateFilters();
                },
                selectedColor: Colors.purple.shade100,
                checkmarkColor: Colors.purple.shade700,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Priority filter
          const Text(
            'Priority',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All Priorities'),
                selected: _priorityFilter == null,
                onSelected: (selected) {
                  setState(() {
                    _priorityFilter = null;
                  });
                  _updateFilters();
                },
                selectedColor: Colors.purple.shade100,
                checkmarkColor: Colors.purple.shade700,
              ),
              ...SchedulePriority.values.map((priority) {
                final isSelected = _priorityFilter == priority;
                return FilterChip(
                  label: Text('${priority.displayName} Priority'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _priorityFilter = selected ? priority : null;
                    });
                    _updateFilters();
                  },
                  selectedColor: Colors.purple.shade100,
                  checkmarkColor: Colors.purple.shade700,
                );
              }),
            ],
          ),
          const SizedBox(height: 32),

          // Clear all filters button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentFilter = ScheduleFilter.all;
                  _priorityFilter = null;
                  _searchQuery = '';
                });
                _updateFilters();
                Navigator.pop(context);
              },
              child: const Text('Clear All Filters'),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
          IconButton(
            onPressed: () => context.push('/workspace/${widget.workspaceId}/calendar'),
            icon: Icon(
              Icons.calendar_today,
              color: Colors.grey.shade700,
              size: 20,
            ),
            tooltip: 'Calendar View',
          ),
          IconButton(
            onPressed: () async {
              final result = await context.push('/workspace/${widget.workspaceId}/create-schedule');
              if (result != null && mounted) {
                _loadSchedules();
              }
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
    final completedToday = _allSchedules.where((s) => s.isToday && s.isCompleted).length;
    final totalToday = _allSchedules.where((s) => s.isToday).length;
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
                const SizedBox(width: 8),
                _buildPriorityChip(schedule.priority),
                if (schedule.isAssigned) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
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
        onTap: () => _navigateToEditSchedule(schedule),
      ),
    );
  }

  Widget _buildPriorityChip(SchedulePriority priority) {
    Color color;
    switch (priority) {
      case SchedulePriority.high:
        color = Colors.red.shade600;
        break;
      case SchedulePriority.medium:
        color = Colors.orange.shade600;
        break;
      case SchedulePriority.low:
        color = Colors.green.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No schedules found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentFilter = ScheduleFilter.all;
                  _priorityFilter = null;
                  _searchQuery = '';
                });
                _updateFilters();
              },
              child: const Text('Clear Filters'),
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