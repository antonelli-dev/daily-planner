// lib/features/schedule/domain/usecases/get_schedule_by_id.usecase.dart
import '../entities/schedule.entity.dart';
import '../repositories/schedule.repository.dart';

class GetScheduleByIdUseCase {
  final ScheduleRepository repository;

  GetScheduleByIdUseCase(this.repository);

  Future<Schedule> call(String workspaceId, String scheduleId) {
    return repository.getScheduleById(workspaceId, scheduleId);
  }
}
