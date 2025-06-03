import '../entities/workspace.entity.dart';
import '../repositories/workspace.repository.dart';

class UpdateWorkspaceUseCase {
  final WorkspaceRepository repository;

  UpdateWorkspaceUseCase(this.repository);

  Future<Workspace> call(String id, String name, {String? description}) {
    return repository.updateWorkspace(id, name, description: description);
  }
}