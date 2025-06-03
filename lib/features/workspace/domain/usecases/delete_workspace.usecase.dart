import '../repositories/workspace.repository.dart';

class DeleteWorkspaceUseCase {
  final WorkspaceRepository repository;

  DeleteWorkspaceUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteWorkspace(id);
  }
}