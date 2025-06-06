// lib/features/schedule/domain/repositories/schedule.repository.dart
import '../entities/schedule.entity.dart';

abstract class ScheduleRepository {
  Future<List<Schedule>> getSchedules(String workspaceId, {DateTime? date});
  Future<Schedule> getScheduleById(String workspaceId, String scheduleId);
  Future<Schedule> createSchedule(String workspaceId, CreateScheduleRequest request);
  Future<Schedule> updateSchedule(String workspaceId, String scheduleId, UpdateScheduleRequest request);
  Future<void> deleteSchedule(String workspaceId, String scheduleId);
  Future<Schedule> completeSchedule(String workspaceId, String scheduleId);
  Future<Schedule> assignSchedule(String workspaceId, String scheduleId, String assignedTo);
}