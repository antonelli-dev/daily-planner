// lib/features/schedule/presentation/calendar_view_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../domain/entities/schedule.entity.dart';
import '../domain/usecases/get_schedules.usecase.dart';
import '../domain/usecases/complete_schedule.usecase.dart';
import '../../../core/shared/widgets/loading_widget.dart';
import '../../../core/shared/widgets/error_widget.dart';
import '../../../core/utils/date_utils.dart';

enum CalendarView { month, week, day }

class CalendarViewScreen extends StatefulWidget {
  final String workspaceId;

  const CalendarViewScreen({
    super.key,
    required this.workspaceId,
  });

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  CalendarView _currentView = CalendarView.month;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<Schedule> _schedules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final getSchedulesUseCase = GetIt.I<GetSchedulesUseCase>();

      // Load schedules for current month/week/day based on view
      List<Schedule> schedules;
      switch (_currentView) {
        case CalendarView.month:
          schedules = await _loadMonthSchedules();
          break;
        case CalendarView.week:
          schedules = await _loadWeekSchedules();
          break;
        case CalendarView.day:
          schedules = await getSchedulesUseCase(widget.workspaceId, date: _selectedDate);
          break;
      }

      setState(() {
        _schedules = schedules;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<Schedule>> _loadMonthSchedules() async {
    final getSchedulesUseCase = GetIt.I<GetSchedulesUseCase>();
    final startOfMonth = AppDateUtils.startOfMonth(_focusedDate);
    final endOfMonth = AppDateUtils.endOfMonth(_focusedDate);
    final days = AppDateUtils.getDaysInRange(startOfMonth, endOfMonth);

    final List<Schedule> allSchedules = [];
    for (final day in days) {
      try {
        final daySchedules = await getSchedulesUseCase(widget.workspaceId, date: day);
        allSchedules.addAll(daySchedules);
      } catch (e) {
        print('Error loading schedules for $day: $e');
      }
    }

    return allSchedules;
  }

  Future<List<Schedule>> _loadWeekSchedules() async {
    final getSchedulesUseCase = GetIt.I<GetSchedulesUseCase>();
    return await getSchedulesUseCase.getSchedulesForWeek(widget.workspaceId, _getWeekStart());
  }

  DateTime _getWeekStart() {
    return AppDateUtils.startOfWeek(_selectedDate);
  }

  Future<void> _completeSchedule(Schedule schedule) async {
    try {
      final completeScheduleUseCase = GetIt.I<CompleteScheduleUseCase>();
      await completeScheduleUseCase(widget.workspaceId, schedule.id);

      _showSnackBar('Schedule marked as completed!', isSuccess: true);
      _loadSchedules();
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

  void _changeView(CalendarView view) {
    setState(() {
      _currentView = view;
    });
    _loadSchedules();
  }

  void _navigateDate(bool forward) {
    setState(() {
      switch (_currentView) {
        case CalendarView.month:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month + (forward ? 1 : -1),
            1,
          );
          break;
        case CalendarView.week:
          _selectedDate = _selectedDate.add(Duration(days: forward ? 7 : -7));
          break;
        case CalendarView.day:
          _selectedDate = _selectedDate.add(Duration(days: forward ? 1 : -1));
          break;
      }
    });
    _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.shade300,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.grey.shade700),
        actions: [
          PopupMenuButton<CalendarView>(
            icon: Icon(Icons.view_module, color: Colors.grey.shade700),
            onSelected: _changeView,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarView.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month),
                    SizedBox(width: 12),
                    Text('Month View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.week,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week),
                    SizedBox(width: 12),
                    Text('Week View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarView.day,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_day),
                    SizedBox(width: 12),
                    Text('Day View'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/workspace/${widget.workspaceId}/create-schedule'),
        backgroundColor: Colors.purple.shade400,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create Schedule',
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentView) {
      case CalendarView.month:
        return '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}';
      case CalendarView.week:
        final weekStart = _getWeekStart();
        final weekEnd = weekStart.add(const Duration(days: 6));
        if (weekStart.month == weekEnd.month) {
          return '${_getMonthName(weekStart.month)} ${weekStart.day}-${weekEnd.day}, ${weekStart.year}';
        } else {
          return '${_getMonthName(weekStart.month)} ${weekStart.day} - ${_getMonthName(weekEnd.month)} ${weekEnd.day}';
        }
      case CalendarView.day:
        return AppDateUtils.formatForDisplay(_selectedDate);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildNavigationHeader(),
        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Loading calendar...')
              : _error != null
              ? CustomErrorWidget.generic(
            message: _error!,
            onRetry: _loadSchedules,
          )
              : RefreshIndicator(
            onRefresh: _loadSchedules,
            child: _buildCalendarContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          IconButton(
            onPressed: () => _navigateDate(false),
            icon: const Icon(Icons.chevron_left),
            color: Colors.grey.shade700,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                      _focusedDate = DateTime.now();
                    });
                    _loadSchedules();
                  },
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: Colors.purple.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _navigateDate(true),
            icon: const Icon(Icons.chevron_right),
            color: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    switch (_currentView) {
      case CalendarView.month:
        return _buildMonthView();
      case CalendarView.week:
        return _buildWeekView();
      case CalendarView.day:
        return _buildDayView();
    }
  }

  Widget _buildMonthView() {
    final startOfMonth = AppDateUtils.startOfMonth(_focusedDate);
    final endOfMonth = AppDateUtils.endOfMonth(_focusedDate);
    final firstDayOfCalendar = startOfMonth.subtract(Duration(days: startOfMonth.weekday - 1));
    final lastDayOfCalendar = endOfMonth.add(Duration(days: 7 - endOfMonth.weekday));

    final calendarDays = AppDateUtils.getDaysInRange(firstDayOfCalendar, lastDayOfCalendar);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: calendarDays.length,
            itemBuilder: (context, index) {
              final day = calendarDays[index];
              final isCurrentMonth = day.month == _focusedDate.month;
              final isToday = AppDateUtils.isToday(day);
              final daySchedules = _schedules.where((s) =>
              s.date.year == day.year &&
                  s.date.month == day.month &&
                  s.date.day == day.day
              ).toList();

              return _buildMonthDayCell(day, isCurrentMonth, isToday, daySchedules);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMonthDayCell(DateTime day, bool isCurrentMonth, bool isToday, List<Schedule> daySchedules) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = day;
          _currentView = CalendarView.day;
        });
        _loadSchedules();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? Colors.purple.shade400
              : isCurrentMonth
              ? Colors.white
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? Colors.purple.shade400
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isToday
                    ? Colors.white
                    : isCurrentMonth
                    ? Colors.black87
                    : Colors.grey.shade400,
              ),
            ),
            if (daySchedules.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : Colors.purple.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final weekStart = _getWeekStart();
    final weekDays = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Week header
          Row(
            children: weekDays.map((day) {
              final isToday = AppDateUtils.isToday(day);
              final daySchedules = _schedules.where((s) =>
              s.date.year == day.year &&
                  s.date.month == day.month &&
                  s.date.day == day.day
              ).toList();

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                      _currentView = CalendarView.day;
                    });
                    _loadSchedules();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.purple.shade400 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isToday ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (daySchedules.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isToday ? Colors.white : Colors.purple.shade400,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Week schedules
          if (_schedules.isNotEmpty)
            ..._schedules.map(_buildScheduleCard)
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final daySchedules = _schedules.where((s) =>
    s.date.year == _selectedDate.year &&
        s.date.month == _selectedDate.month &&
        s.date.day == _selectedDate.day
    ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDateUtils.formatSmart(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${daySchedules.length} schedule${daySchedules.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Day schedules
          if (daySchedules.isNotEmpty)
            ...daySchedules.map(_buildScheduleCard)
          else
            _buildEmptyState(),
        ],
      ),
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
            Text(
              schedule.timeRange,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (schedule.description != null && schedule.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                schedule.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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

  Widget _buildEmptyState() {
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
              'No schedules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No schedules found for this ${_currentView.name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
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