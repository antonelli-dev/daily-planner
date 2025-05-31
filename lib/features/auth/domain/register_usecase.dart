import 'auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<void> register(String email, String password) {
    return repository.register(email, password);
  }
}
