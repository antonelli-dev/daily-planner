import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/login_usecase.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/register_usecase.dart';



final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  final supabase = Supabase.instance.client;

  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(supabase));
  getIt.registerLazySingleton<WorkspaceRepository>(() => WorkspaceRepositoryImpl(supabase));
  getIt.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(supabase));
  getIt.registerLazySingleton<FinanceRepository>(() => FinanceRepositoryImpl(supabase));

  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetWorkspacesUseCase(getIt<WorkspaceRepository>()));
  getIt.registerLazySingleton(() => GetSchedulesUseCase(getIt<ScheduleRepository>()));

}
