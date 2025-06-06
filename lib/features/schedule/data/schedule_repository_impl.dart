// lib/features/schedule/data/schedule_repository_impl.dart
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/repositories/schedule.repository.dart';
import '../domain/entities/schedule.entity.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ApiClient _apiClient;

  ScheduleRepositoryImpl(this._apiClient);

  @override
  Future<List<Schedule>> getSchedules(String workspaceId, {DateTime? date}) async {
    final Map<String, dynamic> queryParams = {};

    if (date != null) {
      queryParams['date'] = AppDateUtils.formatForApi(date);
    }

    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.schedules(workspaceId),
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    return response.when(
      success: (data) {
        if (data is List) {
          return data
              .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          return <Schedule>[];
        }
      },
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Schedule> getScheduleById(String workspaceId, String scheduleId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.schedule(workspaceId, scheduleId),
    );

    return response.when(
      success: (data) => Schedule.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Schedule> createSchedule(String workspaceId, CreateScheduleRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.schedules(workspaceId),
      body: request.toJson(),
    );

    return response.when(
      success: (data) => Schedule.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Schedule> updateSchedule(String workspaceId, String scheduleId, UpdateScheduleRequest request) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.schedule(workspaceId, scheduleId),
      body: request.toJson(),
    );

    return response.when(
      success: (data) => Schedule.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> deleteSchedule(String workspaceId, String scheduleId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.schedule(workspaceId, scheduleId),
    );

    response.when(
      success: (_) => null,
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Schedule> completeSchedule(String workspaceId, String scheduleId) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.completeSchedule(workspaceId, scheduleId),
    );

    return response.when(
      success: (data) => Schedule.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Schedule> assignSchedule(String workspaceId, String scheduleId, String assignedTo) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      ApiEndpoints.assignSchedule(workspaceId, scheduleId),
      body: {'assignedTo': assignedTo},
    );

    return response.when(
      success: (data) => Schedule.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }
}