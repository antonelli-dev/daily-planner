import '../entities/workspace.entity.dart';
import '../entities/workspace_member.dart';

abstract class WorkspaceRepository {
  Future<List<Workspace>> getWorkspaces();
  Future<Workspace> getWorkspaceById(String id);
  Future<Workspace> createWorkspace(String name, {String? description});
  Future<Workspace> updateWorkspace(String id, String name, {String? description});
  Future<void> deleteWorkspace(String id);

  // Member management
  Future<List<WorkspaceMember>> getWorkspaceMembers(String workspaceId);
  Future<WorkspaceMember> inviteMember(String workspaceId, String email, String role);
  Future<void> removeMember(String workspaceId, String userId);

  // Invitations
  Future<List<WorkspaceMember>> getPendingInvitations();
  Future<WorkspaceMember> acceptInvitation(String workspaceId);
  Future<void> rejectInvitation(String workspaceId);
}