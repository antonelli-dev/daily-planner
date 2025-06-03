import '../entities/workspace.entity.dart';
import '../repositories/workspace.repository.dart';

class GetWorkspacesUseCase {
  final WorkspaceRepository repository;

  GetWorkspacesUseCase(this.repository);

  Future<List<Workspace>> call() {
    return repository.getWorkspaces();
  }
}