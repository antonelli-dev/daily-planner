import '../entities/workspace_member.dart';
import '../repositories/workspace.repository.dart';

class GetWorkspaceMembersUseCase {
  final WorkspaceRepository repository;

  GetWorkspaceMembersUseCase(this.repository);

  Future<List<WorkspaceMember>> call(String workspaceId) {
    return repository.getWorkspaceMembers(workspaceId);
  }
}