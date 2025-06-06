// lib/features/schedule/domain/usecases/create_schedule.usecase.dart
import '../entities/schedule.entity.dart';
import '../repositories/schedule.repository.dart';

class CreateScheduleUseCase {
  final ScheduleRepository repository;

  CreateScheduleUseCase(this.repository);

  Future<Schedule> call(String workspaceId, CreateScheduleRequest request) {
    // Validate the request
    _validateRequest(request);

    return repository.createSchedule(workspaceId, request);
  }

  void _validateRequest(CreateScheduleRequest request) {
    if (request.title.trim().isEmpty) {
      throw ArgumentError('Schedule title cannot be empty');
    }

    if (request.title.length > 100) {
      throw ArgumentError('Schedule title must be less than 100 characters');
    }

    if (request.description != null && request.description!.length > 500) {
      throw ArgumentError('Schedule description must be less than 500 characters');
    }

    if (request.durationMinutes <= 0) {
      throw ArgumentError('Duration must be greater than 0 minutes');
    }

    if (request.durationMinutes > 1440) { // 24 hours
      throw ArgumentError('Duration cannot exceed 24 hours');
    }

    // Validate date is not in the past (allow today)
    final today = DateTime.now();
    final requestDate = DateTime(request.date.year, request.date.month, request.date.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    if (requestDate.isBefore(todayDate)) {
      throw ArgumentError('Cannot create schedule for past dates');
    }

    // Validate color format (hex color)
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(request.color)) {
      throw ArgumentError('Invalid color format. Use hex format like #FF6B6B');
    }
  }
}