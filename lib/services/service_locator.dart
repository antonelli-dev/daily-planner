import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/login_usecase.dart';
import '../features/auth/data/auth_repository_impl.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  final supabase = Supabase.instance.client;

  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(supabase));

  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
}
