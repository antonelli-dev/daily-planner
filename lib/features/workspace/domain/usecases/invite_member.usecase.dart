import '../entities/workspace_member.dart';
import '../repositories/workspace.repository.dart';

class InviteMemberUseCase {
  final WorkspaceRepository repository;

  InviteMemberUseCase(this.repository);

  Future<WorkspaceMember> call(String workspaceId, String email, String role) {
    // Validate role
    if (!['admin', 'member'].contains(role)) {
      throw ArgumentError('Invalid role. Must be either "admin" or "member"');
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }

    return repository.inviteMember(workspaceId, email, role);
  }
}