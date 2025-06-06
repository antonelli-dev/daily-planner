// lib/features/schedule/domain/usecases/get_schedule_by_id.usecase.dart
import '../entities/schedule.entity.dart';
import '../repositories/schedule.repository.dart';

class GetScheduleByIdUseCase {
  final ScheduleRepository repository;

  GetScheduleByIdUseCase(this.repository);

  Future<Schedule> call(String workspaceId, String scheduleId) async {
    if (workspaceId.trim().isEmpty) {
      throw ArgumentError('Workspace ID cannot be empty');
    }

    if (scheduleId.trim().isEmpty) {
      throw ArgumentError('Schedule ID cannot be empty');
    }

    try {
      return await repository.getScheduleById(workspaceId, scheduleId);
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('404') || errorMessage.contains('not found')) {
        throw Exception('Schedule not found. It may have been deleted or moved.');
      } else if (errorMessage.contains('403') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('permission')) {
        throw Exception('You don\'t have permission to view this schedule.');
      } else if (errorMessage.contains('401') || errorMessage.contains('authentication')) {
        throw Exception('Authentication failed. Please sign in again.');
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        throw Exception('Network error. Please check your connection and try again.');
      } else if (errorMessage.contains('500') || errorMessage.contains('server')) {
        throw Exception('Server error. Please try again later.');
      } else {
        // For any other errors, provide a generic but helpful message
        throw Exception('Failed to load schedule. Please try again.');
      }
    }
  }
}