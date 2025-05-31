import 'auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<void> login(String email, String password) {
    return repository.login(email, password);
  }
}
