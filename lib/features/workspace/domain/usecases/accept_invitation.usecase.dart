import '../entities/workspace_member.dart';
import '../repositories/workspace.repository.dart';

class AcceptInvitationUseCase {
  final WorkspaceRepository repository;

  AcceptInvitationUseCase(this.repository);

  Future<WorkspaceMember> call(String workspaceId) {
    return repository.acceptInvitation(workspaceId);
  }
}