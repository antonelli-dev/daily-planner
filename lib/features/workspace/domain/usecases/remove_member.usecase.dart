import '../repositories/workspace.repository.dart';

class RemoveMemberUseCase {
  final WorkspaceRepository repository;

  RemoveMemberUseCase(this.repository);

  Future<void> call(String workspaceId, String userId) {
    return repository.removeMember(workspaceId, userId);
  }
}