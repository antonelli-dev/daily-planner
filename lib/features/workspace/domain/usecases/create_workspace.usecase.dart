import '../entities/workspace.entity.dart';
import '../repositories/workspace.repository.dart';

class CreateWorkspaceUseCase {
  final WorkspaceRepository repository;

  CreateWorkspaceUseCase(this.repository);

  Future<Workspace> call(String name, {String? description}) {
    return repository.createWorkspace(name, description: description);
  }
}