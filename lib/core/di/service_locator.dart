// lib/core/di/service_locator.dart
//
// Registration order matters — dependencies must be registered
// before anything that depends on them.
// Order: datasources → repositories → use cases → blocs

import "package:get_it/get_it.dart";

// ── Data layer ────────────────────────────────────────────
import "package:valoqui/core/data/datasources/firebase_auth_datasource.dart";
import "package:valoqui/core/data/datasources/firestore_datasource.dart";
import "package:valoqui/core/data/datasources/secure_storage_datasource.dart";
import "package:valoqui/core/data/repositories/android_key_storage_repository.dart";
import "package:valoqui/core/data/repositories/firebase_auth_repository.dart";
import "package:valoqui/core/data/repositories/firebase_user_repository.dart";

// ── Domain interfaces ─────────────────────────────────────
import "package:valoqui/core/domain/repositories/user_repository.dart";
import "package:valoqui/core/domain/repositories/auth_repository.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";

// ── Use cases — auth ──────────────────────────────────────
import "package:valoqui/core/domain/usecases/auth/sign_in_with_google.dart";
import "package:valoqui/core/domain/usecases/auth/sign_out.dart";
import "package:valoqui/core/domain/usecases/auth/watch_auth_state.dart";

// ── Use cases — user ──────────────────────────────────────
import "package:valoqui/core/domain/usecases/user/update_user_level.dart";
import "package:valoqui/core/domain/usecases/user/watch_user_profile.dart";

// ── Use cases — onboarding ────────────────────────────────
import "package:valoqui/core/domain/usecases/onboarding/check_onboarding_status.dart";
import "package:valoqui/core/domain/usecases/onboarding/mark_onboarding_complete.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_gemini_key.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_groq_key.dart";

// ── BLoCs ─────────────────────────────────────────────────
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";

// ── Network ───────────────────────────────────────────────
import "package:valoqui/core/network/dio_client.dart";

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Step 1: Data sources (singletons) ────────────────────
  // Raw SDK wrappers — one instance for the app lifetime

  sl.registerLazySingleton<FirebaseAuthDatasource>(
    () => FirebaseAuthDatasource(),
  );

  sl.registerLazySingleton<FirestoreDatasource>(() => FirestoreDatasource());

  sl.registerLazySingleton<SecureStorageDatasource>(
    () => SecureStorageDatasource(),
  );

  // ── Step 2: Repositories (singletons) ────────────────────
  // Registered against their INTERFACES — the rest of the app
  // depends on the interface type, never the concrete class

  sl.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(datasource: sl<FirebaseAuthDatasource>()),
  );

  sl.registerLazySingleton<UserRepository>(
    () => FirebaseUserRepository(datasource: sl<FirestoreDatasource>()),
  );

  sl.registerLazySingleton<KeyStorageRepository>(
    () =>
        AndroidKeyStorageRepository(datasource: sl<SecureStorageDatasource>()),
  );

  // ── Step 3: Network (singleton) ───────────────────────────
  // DioClient needs KeyStorageRepository for the interceptor
  sl.registerLazySingleton<DioClient>(
    () => DioClient(keyStorage: sl<KeyStorageRepository>()),
  );

  // ── Step 4: Use cases (singletons) ───────────────────────
  // Use cases are stateless — singleton is fine

  sl.registerLazySingleton<SignInWithGoogle>(
    () => SignInWithGoogle(
      authRepository: sl<AuthRepository>(),
      userRepository: sl<UserRepository>(),
    ),
  );

  sl.registerLazySingleton<SignOut>(
    () => SignOut(authRepository: sl<AuthRepository>()),
  );

  sl.registerLazySingleton<WatchAuthState>(
    () => WatchAuthState(authRepository: sl<AuthRepository>()),
  );

  sl.registerLazySingleton<WatchUserProfile>(
    () => WatchUserProfile(userRepository: sl<UserRepository>()),
  );

  sl.registerLazySingleton<UpdateUserLevel>(
    () => UpdateUserLevel(userRepository: sl<UserRepository>()),
  );

  sl.registerLazySingleton<CheckOnboardingStatus>(
    () => CheckOnboardingStatus(keyStorage: sl<KeyStorageRepository>()),
  );

  sl.registerLazySingleton<SaveGroqKey>(
    () => SaveGroqKey(
      keyStorage: sl<KeyStorageRepository>(),
      userRepository: sl<UserRepository>(),
    ),
  );

  sl.registerLazySingleton<SaveGeminiKey>(
    () => SaveGeminiKey(
      keyStorage: sl<KeyStorageRepository>(),
      userRepository: sl<UserRepository>(),
    ),
  );

  sl.registerLazySingleton<MarkOnboardingComplete>(
    () => MarkOnboardingComplete(keyStorage: sl<KeyStorageRepository>()),
  );

  // ── Step 5: BLoCs (factories) ─────────────────────────────
  // New instance per request — BLoCs carry state so they must
  // not be shared across widget tree rebuilds

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      signInWithGoogle: sl<SignInWithGoogle>(),
      signOut: sl<SignOut>(),
      watchAuthState: sl<WatchAuthState>(),
    ),
  );

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(watchUserProfile: sl<WatchUserProfile>()),
  );

  sl.registerFactory<OnboardingBloc>(
    () => OnboardingBloc(
      checkOnboardingStatus: sl<CheckOnboardingStatus>(),
      saveGroqKey: sl<SaveGroqKey>(),
      saveGeminiKey: sl<SaveGeminiKey>(),
      markOnboardingComplete: sl<MarkOnboardingComplete>(),
      updateUserLevel: sl<UpdateUserLevel>(),
    ),
  );
}
