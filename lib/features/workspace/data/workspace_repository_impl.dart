import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../domain/repositories/workspace.repository.dart';
import '../domain/entities/workspace.entity.dart';
import '../domain/entities/workspace_member.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final ApiClient _apiClient;

  WorkspaceRepositoryImpl(this._apiClient);

  @override
  Future<List<Workspace>> getWorkspaces() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.workspaces,
    );

    return response.when(
      success: (data) {
        // API returns: {"data": [...], "success": true}
        // The data is already extracted by ApiClient
        if (data is List) {
          return data
              .map((json) => Workspace.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // If no workspaces, return empty list
          return <Workspace>[];
        }
      },
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Workspace> getWorkspaceById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.workspace(id),
    );

    return response.when(
      success: (data) => Workspace.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Workspace> createWorkspace(String name, {String? description}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.workspaces,
      body: {
        'name': name,
        if (description != null) 'description': description,
      },
    );

    return response.when(
      success: (data) => Workspace.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<Workspace> updateWorkspace(String id, String name, {String? description}) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.workspace(id),
      body: {
        'name': name,
        if (description != null) 'description': description,
      },
    );

    return response.when(
      success: (data) => Workspace.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.workspace(id));

    response.when(
      success: (_) => null,
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<List<WorkspaceMember>> getWorkspaceMembers(String workspaceId) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.workspaceMembers(workspaceId),
    );

    return response.when(
      success: (data) {
        // API returns: {"data": [...], "success": true}
        if (data is List) {
          return data
              .map((json) => WorkspaceMember.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // If no members, return empty list
          return <WorkspaceMember>[];
        }
      },
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<WorkspaceMember> inviteMember(String workspaceId, String email, String role) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.inviteMember(workspaceId),
      body: {
        'email': email,
        'role': role,
      },
    );

    return response.when(
      success: (data) => WorkspaceMember.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> removeMember(String workspaceId, String userId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.removeMember(workspaceId, userId),
    );

    response.when(
      success: (_) => null,
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<List<WorkspaceMember>> getPendingInvitations() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.pendingInvitations,
    );

    return response.when(
      success: (data) {
        // API returns: {"data": [...], "success": true}
        if (data is List) {
          return data
              .map((json) => WorkspaceMember.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // If no pending invitations, return empty list
          return <WorkspaceMember>[];
        }
      },
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<WorkspaceMember> acceptInvitation(String workspaceId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.acceptInvitation(workspaceId),
    );

    return response.when(
      success: (data) => WorkspaceMember.fromJson(data),
      error: (error, statusCode) => throw Exception(error),
    );
  }

  @override
  Future<void> rejectInvitation(String workspaceId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.rejectInvitation(workspaceId),
    );

    response.when(
      success: (_) => null,
      error: (error, statusCode) => throw Exception(error),
    );
  }
}