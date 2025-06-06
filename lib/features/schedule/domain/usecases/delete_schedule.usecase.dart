// lib/features/schedule/domain/usecases/delete_schedule.usecase.dart
import '../repositories/schedule.repository.dart';

class DeleteScheduleUseCase {
  final ScheduleRepository repository;

  DeleteScheduleUseCase(this.repository);

  Future<void> call(String workspaceId, String scheduleId) {
    return repository.deleteSchedule(workspaceId, scheduleId);
  }
}