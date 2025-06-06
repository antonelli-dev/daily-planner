// lib/features/schedule/domain/usecases/update_schedule.usecase.dart
import '../entities/schedule.entity.dart';
import '../repositories/schedule.repository.dart';

class UpdateScheduleUseCase {
  final ScheduleRepository repository;

  UpdateScheduleUseCase(this.repository);

  Future<Schedule> call(String workspaceId, String scheduleId, UpdateScheduleRequest request) {
    // Validate the request
    _validateRequest(request);

    return repository.updateSchedule(workspaceId, scheduleId, request);
  }

  void _validateRequest(UpdateScheduleRequest request) {
    if (request.title != null) {
      if (request.title!.trim().isEmpty) {
        throw ArgumentError('Schedule title cannot be empty');
      }
      if (request.title!.length > 100) {
        throw ArgumentError('Schedule title must be less than 100 characters');
      }
    }

    if (request.description != null && request.description!.length > 500) {
      throw ArgumentError('Schedule description must be less than 500 characters');
    }

    if (request.durationMinutes != null) {
      if (request.durationMinutes! <= 0) {
        throw ArgumentError('Duration must be greater than 0 minutes');
      }
      if (request.durationMinutes! > 1440) {
        throw ArgumentError('Duration cannot exceed 24 hours');
      }
    }

    if (request.color != null) {
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(request.color!)) {
        throw ArgumentError('Invalid color format. Use hex format like #FF6B6B');
      }
    }
  }
}