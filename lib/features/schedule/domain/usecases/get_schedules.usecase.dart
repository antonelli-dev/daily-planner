// lib/features/schedule/domain/usecases/get_schedules.usecase.dart
import '../entities/schedule.entity.dart';
import '../repositories/schedule.repository.dart';

class GetSchedulesUseCase {
  final ScheduleRepository repository;

  GetSchedulesUseCase(this.repository);

  Future<List<Schedule>> call(String workspaceId, {DateTime? date}) {
    return repository.getSchedules(workspaceId, date: date);
  }

  Future<List<Schedule>> getTodaySchedules(String workspaceId) {
    return call(workspaceId, date: DateTime.now());
  }

  Future<List<Schedule>> getSchedulesForWeek(String workspaceId, DateTime startDate) async {
    final List<Schedule> allSchedules = [];

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final daySchedules = await call(workspaceId, date: date);
      allSchedules.addAll(daySchedules);
    }

    return allSchedules;
  }
}