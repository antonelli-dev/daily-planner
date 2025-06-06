// lib/features/schedule/domain/usecases/complete_schedule.usecase.dart
import '../entities/schedule.entity.dart';
import '../repositories/schedule.repository.dart';

class CompleteScheduleUseCase {
  final ScheduleRepository repository;

  CompleteScheduleUseCase(this.repository);

  Future<Schedule> call(String workspaceId, String scheduleId) {
    return repository.completeSchedule(workspaceId, scheduleId);
  }
}