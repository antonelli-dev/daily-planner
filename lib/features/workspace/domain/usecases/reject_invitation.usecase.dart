import '../repositories/workspace.repository.dart';

class RejectInvitationUseCase {
  final WorkspaceRepository repository;

  RejectInvitationUseCase(this.repository);

  Future<void> call(String workspaceId) {
    return repository.rejectInvitation(workspaceId);
  }
}