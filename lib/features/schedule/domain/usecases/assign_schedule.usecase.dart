// lib/features/schedule/domain/usecases/assign_schedule.usecase.dart
import '../entities/schedule.entity.dart';
import '../repositories/schedule.repository.dart';

class AssignScheduleUseCase {
  final ScheduleRepository repository;

  AssignScheduleUseCase(this.repository);

  Future<Schedule> call(String workspaceId, String scheduleId, String assignedTo) {
    // Validate assignedTo is not empty
    if (assignedTo.trim().isEmpty) {
      throw ArgumentError('Assigned user ID cannot be empty');
    }

    return repository.assignSchedule(workspaceId, scheduleId, assignedTo);
  }
}