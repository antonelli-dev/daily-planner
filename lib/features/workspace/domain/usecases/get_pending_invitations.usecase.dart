import '../entities/workspace_member.dart';
import '../repositories/workspace.repository.dart';

class GetPendingInvitationsUseCase {
  final WorkspaceRepository repository;

  GetPendingInvitationsUseCase(this.repository);

  Future<List<WorkspaceMember>> call() {
    return repository.getPendingInvitations();
  }
}