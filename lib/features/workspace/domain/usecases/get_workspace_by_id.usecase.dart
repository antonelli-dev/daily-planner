import '../entities/workspace.entity.dart';
import '../repositories/workspace.repository.dart';

class GetWorkspaceUseCase {
  final WorkspaceRepository repository;

  GetWorkspaceUseCase(this.repository);

  Future<Workspace> call(String id) {
    return repository.getWorkspaceById(id);
  }
}