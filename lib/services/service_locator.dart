import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import '../core/api/api_client.dart';

// Auth
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/login_usecase.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/register_usecase.dart';

// Workspace
import '../features/workspace/domain/repositories/workspace.repository.dart';
import '../features/workspace/data/workspace_repository_impl.dart';
import '../features/workspace/domain/usecases/get_workspaces.usecase.dart';
import '../features/workspace/domain/usecases/create_workspace.usecase.dart';
import '../features/workspace/domain/usecases/update_workspace.usecase.dart';
import '../features/workspace/domain/usecases/delete_workspace.usecase.dart';
import '../features/workspace/domain/usecases/get_workspace_by_id.usecase.dart';
import '../features/workspace/domain/usecases/invite_member.usecase.dart';
import '../features/workspace/domain/usecases/remove_member.usecase.dart';
import '../features/workspace/domain/usecases/get_workspace_members.usecase.dart';
import '../features/workspace/domain/usecases/get_pending_invitations.usecase.dart';
import '../features/workspace/domain/usecases/accept_invitation.usecase.dart';
import '../features/workspace/domain/usecases/reject_invitation.usecase.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  final supabase = Supabase.instance.client;

  // Core services
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(supabase));

  // Auth repositories and use cases
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(supabase));
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));

  // Workspace repositories and use cases
  getIt.registerLazySingleton<WorkspaceRepository>(() => WorkspaceRepositoryImpl(getIt<ApiClient>()));

  // Workspace use cases - using correct class names
  getIt.registerLazySingleton(() => GetWorkspacesUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => CreateWorkspaceUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => UpdateWorkspaceUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => DeleteWorkspaceUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => GetWorkspaceUseCase(getIt<WorkspaceRepository>())); // This might be GetWorkspaceByIdUseCase
  getIt.registerLazySingleton(() => InviteMemberUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => RemoveMemberUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => GetWorkspaceMembersUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => GetPendingInvitationsUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => AcceptInvitationUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => RejectInvitationUseCase(getIt<WorkspaceRepository>()));
}