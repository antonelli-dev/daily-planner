// lib/features/schedule/presentation/create_task_screen.dart
// Fixed version with proper navigation results

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../domain/entities/schedule.entity.dart';
import '../domain/usecases/create_schedule.usecase.dart';
import '../domain/usecases/update_schedule.usecase.dart';
import '../domain/usecases/delete_schedule.usecase.dart';
import '../domain/usecases/get_schedule_by_id.usecase.dart';
import '../../workspace/domain/usecases/get_workspace_members.usecase.dart';
import '../../workspace/domain/entities/workspace_member.dart';

class CreateTaskScreen extends StatefulWidget {
  final String workspaceId;
  final String? scheduleId; // null for create, populated for edit

  const CreateTaskScreen({
    super.key,
    required this.workspaceId,
    this.scheduleId,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 60;
  String _selectedColor = ScheduleConstants.defaultColors.first;
  String _selectedIcon = ScheduleConstants.defaultIcons.first;
  SchedulePriority _selectedPriority = SchedulePriority.medium;
  String? _selectedAssignee;

  bool _loading = false;
  bool _loadingInitial = false;
  List<WorkspaceMember> _workspaceMembers = [];
  Schedule? _existingSchedule;

  bool get isEditing => widget.scheduleId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loadingInitial = true);

    try {
      // Load workspace members for assignment
      final getMembersUseCase = GetIt.I<GetWorkspaceMembersUseCase>();
      final members = await getMembersUseCase(widget.workspaceId);

      // If editing, load existing schedule
      Schedule? schedule;
      if (isEditing) {
        final getScheduleUseCase = GetIt.I<GetScheduleByIdUseCase>();
        schedule = await getScheduleUseCase(widget.workspaceId, widget.scheduleId!);
        _populateFormWithSchedule(schedule);
      }

      if (mounted) {
        setState(() {
          _workspaceMembers = members.where((m) => m.isActive).toList();
          _existingSchedule = schedule;
          _loadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingInitial = false);

        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.contains('not found')) {
          errorMessage = 'This schedule no longer exists. It may have been deleted.';
          // Navigate back after showing error
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) context.pop();
          });
        } else if (errorMessage.contains('permission') || errorMessage.contains('unauthorized')) {
          errorMessage = 'You don\'t have permission to edit this schedule.';
        } else if (errorMessage.contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }

        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _populateFormWithSchedule(Schedule schedule) {
    _titleController.text = schedule.title;
    _descriptionController.text = schedule.description ?? '';
    _selectedDate = schedule.date;
    _selectedTime = TimeOfDay.fromDateTime(schedule.startTime);
    _durationMinutes = schedule.durationMinutes.clamp(15, 480);

    // Validate color format
    if (ScheduleConstants.defaultColors.contains(schedule.color)) {
      _selectedColor = schedule.color;
    } else {
      _selectedColor = ScheduleConstants.defaultColors.first;
    }

    // Validate icon
    if (ScheduleConstants.defaultIcons.contains(schedule.icon)) {
      _selectedIcon = schedule.icon;
    } else {
      _selectedIcon = ScheduleConstants.defaultIcons.first;
    }

    _selectedPriority = schedule.priority;
    _selectedAssignee = schedule.assignedTo;
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (isEditing) {
        // Update existing schedule
        final updateUseCase = GetIt.I<UpdateScheduleUseCase>();
        final request = UpdateScheduleRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
          startTime: startDateTime,
          durationMinutes: _durationMinutes,
          color: _selectedColor,
          icon: _selectedIcon,
          priority: _selectedPriority,
          assignedTo: _selectedAssignee,
        );

        final updatedSchedule = await updateUseCase(widget.workspaceId, widget.scheduleId!, request);

        if (mounted) {
          _showSuccessSnackBar('Schedule updated successfully!');
          // Return the updated schedule so the calling screen can update its state
          context.pop(updatedSchedule);
        }
      } else {
        // Create new schedule
        final createUseCase = GetIt.I<CreateScheduleUseCase>();
        final request = CreateScheduleRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: _selectedDate,
          startTime: startDateTime,
          durationMinutes: _durationMinutes,
          color: _selectedColor,
          icon: _selectedIcon,
          priority: _selectedPriority,
          assignedTo: _selectedAssignee,
        );

        final newSchedule = await createUseCase(widget.workspaceId, request);

        if (mounted) {
          _showSuccessSnackBar('Schedule created successfully!');
          // Return the new schedule so the calling screen can update its state
          context.pop(newSchedule);
        }
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      if (errorMessage.contains('validation')) {
        errorMessage = 'Please check your input and try again.';
      } else if (errorMessage.contains('conflict')) {
        errorMessage = 'This time slot conflicts with another schedule.';
      } else if (errorMessage.contains('permission')) {
        errorMessage = 'You don\'t have permission to modify this schedule.';
      } else {
        errorMessage = 'Error ${isEditing ? 'updating' : 'creating'} schedule: $errorMessage';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteSchedule() async {
    if (!isEditing || _existingSchedule == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Delete Schedule'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_existingSchedule!.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _showLoadingSnackBar('Deleting schedule...');

      final deleteUseCase = GetIt.I<DeleteScheduleUseCase>();
      await deleteUseCase(widget.workspaceId, widget.scheduleId!);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSuccessSnackBar('Schedule deleted successfully!');

        // Wait a moment then navigate back with 'deleted' result
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop('deleted');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('Error deleting schedule: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _duplicateSchedule() {
    if (_existingSchedule == null) return;

    // Adjust form for duplication
    _titleController.text = '${_existingSchedule!.title} (Copy)';
    _selectedDate = DateTime.now().add(const Duration(days: 1));

    _showSnackBar('Ready to create a duplicate. Adjust details as needed.', isSuccess: true);
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.info_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLoadingSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        isEditing ? 'Edit Schedule' : 'Create Schedule',
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
      iconTheme: IconThemeData(color: Colors.grey.shade700),
      actions: [
        if (isEditing)
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _deleteSchedule();
                  break;
                case 'duplicate':
                  _duplicateSchedule();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        if (!_loading)
          TextButton(
            onPressed: _saveSchedule,
            child: Text(
              isEditing ? 'Update' : 'Save',
              style: TextStyle(
                color: Colors.purple.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              enabled: !_loading,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter schedule title',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.length > 100) {
                  return 'Title must be less than 100 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              enabled: !_loading,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add more details about this schedule...',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                ),
              ),
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Description must be less than 500 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Date and Time Section
            _buildSectionTitle('Date & Time'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDateSelector()),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeSelector()),
              ],
            ),
            const SizedBox(height: 16),
            _buildDurationSelector(),
            const SizedBox(height: 32),

            // Visual Settings Section
            _buildSectionTitle('Visual Settings'),
            const SizedBox(height: 16),
            _buildColorSelector(),
            const SizedBox(height: 16),
            _buildIconSelector(),
            const SizedBox(height: 32),

            // Priority Section
            _buildSectionTitle('Priority'),
            const SizedBox(height: 16),
            _buildPrioritySelector(),
            const SizedBox(height: 32),

            // Assignment Section (only for team workspaces)
            if (_workspaceMembers.isNotEmpty) ...[
              _buildSectionTitle('Assignment'),
              const SizedBox(height: 16),
              _buildAssignmentSelector(),
              const SizedBox(height: 32),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(isEditing ? Icons.save : Icons.add),
                label: Text(
                  _loading
                      ? (isEditing ? 'Updating...' : 'Creating...')
                      : (isEditing ? 'Update Schedule' : 'Create Schedule'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Date'),
        subtitle: Text(
          _selectedDate.day == DateTime.now().day &&
              _selectedDate.month == DateTime.now().month &&
              _selectedDate.year == DateTime.now().year
              ? 'Today'
              : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: TextStyle(color: Colors.purple.shade600, fontWeight: FontWeight.w500),
        ),
        onTap: _loading ? null : _selectDate,
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: const Text('Time'),
        subtitle: Text(
          _selectedTime.format(context),
          style: TextStyle(color: Colors.purple.shade600, fontWeight: FontWeight.w500),
        ),
        onTap: _loading ? null : _selectTime,
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer),
              const SizedBox(width: 12),
              const Text(
                'Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${_durationMinutes ~/ 60}h ${_durationMinutes % 60}m',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _durationMinutes.toDouble(),
            min: 15,
            max: 480, // 8 hours
            divisions: 31, // 15 min increments
            activeColor: Colors.purple.shade400,
            onChanged: _loading
                ? null
                : (value) {
              setState(() {
                _durationMinutes = value.round();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette),
              SizedBox(width: 12),
              Text(
                'Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ScheduleConstants.defaultColors.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: _loading
                    ? null
                    : () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(color),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: _parseColor(color).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category),
              SizedBox(width: 12),
              Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ScheduleConstants.defaultIcons.map((iconName) {
              final isSelected = iconName == _selectedIcon;
              return GestureDetector(
                onTap: _loading
                    ? null
                    : () {
                  setState(() {
                    _selectedIcon = iconName;
                  });
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _parseColor(_selectedColor).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: _parseColor(_selectedColor), width: 2)
                        : Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconData(iconName),
                        color: isSelected
                            ? _parseColor(_selectedColor)
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ScheduleConstants.iconLabels[iconName] ?? iconName,
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected
                              ? _parseColor(_selectedColor)
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: SchedulePriority.values.map((priority) {
          return RadioListTile<SchedulePriority>(
            title: Text(priority.displayName),
            subtitle: Text(_getPriorityDescription(priority)),
            value: priority,
            groupValue: _selectedPriority,
            onChanged: _loading
                ? null
                : (value) {
              setState(() {
                _selectedPriority = value!;
              });
            },
            activeColor: Colors.purple.shade400,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAssignmentSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedAssignee,
        decoration: InputDecoration(
          labelText: 'Assign to team member',
          prefixIcon: const Icon(Icons.person_add),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
          ),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Unassigned'),
          ),
          ..._workspaceMembers.map((member) {
            return DropdownMenuItem<String>(
              value: member.userId,
              child: Text(member.userEmail ?? 'Unknown Member'),
            );
          }),
        ],
        onChanged: _loading
            ? null
            : (value) {
          setState(() {
            _selectedAssignee = value;
          });
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    // When editing, allow past dates if it's the original date
    DateTime firstDate = DateTime.now();
    if (isEditing && _existingSchedule != null) {
      firstDate = _existingSchedule!.date.isBefore(DateTime.now())
          ? _existingSchedule!.date
          : DateTime.now();
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade400,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade400,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  String _getPriorityDescription(SchedulePriority priority) {
    switch (priority) {
      case SchedulePriority.low:
        return 'Low importance, flexible timing';
      case SchedulePriority.medium:
        return 'Normal priority, regular scheduling';
      case SchedulePriority.high:
        return 'High importance, critical timing';
    }
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