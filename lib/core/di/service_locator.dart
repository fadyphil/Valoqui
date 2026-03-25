// lib/core/di/service_locator.dart
//
// Registration order matters — dependencies must be registered
// before anything that depends on them.
// Order: datasources → repositories → use cases → blocs

import "package:get_it/get_it.dart";

// ── Sprint 1: Data layer ──────────────────────────────────────
import "package:valoqui/core/data/datasources/firebase_auth_datasource.dart";
import "package:valoqui/core/data/datasources/firestore_datasource.dart";
import "package:valoqui/core/data/datasources/secure_storage_datasource.dart";
import "package:valoqui/core/data/repositories/android_key_storage_repository.dart";
import "package:valoqui/core/data/repositories/firebase_auth_repository.dart";
import "package:valoqui/core/data/repositories/firebase_user_repository.dart";

// ── Sprint 1: Domain interfaces ───────────────────────────────
import "package:valoqui/core/domain/repositories/user_repository.dart";
import "package:valoqui/core/domain/repositories/auth_repository.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";

// ── Sprint 1: Use cases — auth ────────────────────────────────
import "package:valoqui/core/domain/usecases/auth/sign_in_with_google.dart";
import "package:valoqui/core/domain/usecases/auth/sign_out.dart";
import "package:valoqui/core/domain/usecases/auth/watch_auth_state.dart";

// ── Sprint 1: Use cases — user ────────────────────────────────
import "package:valoqui/core/domain/usecases/user/update_user_level.dart";
import "package:valoqui/core/domain/usecases/user/watch_user_profile.dart";

// ── Sprint 1: Use cases — onboarding ─────────────────────────
import "package:valoqui/core/domain/usecases/onboarding/check_onboarding_status.dart";
import "package:valoqui/core/domain/usecases/onboarding/mark_onboarding_complete.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_gemini_key.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_groq_key.dart";

// ── Sprint 1: BLoCs ───────────────────────────────────────────
import "package:valoqui/features/auth/bloc/auth_bloc.dart";
import "package:valoqui/features/home/bloc/home_bloc.dart";
import "package:valoqui/features/onboarding/bloc/onboarding_bloc.dart";

// ── Sprint 1: Network ─────────────────────────────────────────
import "package:valoqui/core/network/dio_client.dart";

// ── Sprint 2: Datasources ─────────────────────────────────────
import "package:valoqui/core/data/datasources/android_stt_datasource.dart";
import "package:valoqui/core/data/datasources/sherpa_tts_datasource.dart";
import "package:valoqui/core/data/datasources/sherpa_vad_datasource.dart";
import "package:valoqui/core/data/datasources/groq_llm_datasource.dart";
import "package:valoqui/core/data/datasources/gemini_llm_datasource.dart";

// ── Sprint 2: Repositories ────────────────────────────────────
import "package:valoqui/core/data/repositories/android_stt_repository.dart";
import "package:valoqui/core/data/repositories/sherpa_tts_repository.dart";
import "package:valoqui/core/data/repositories/sherpa_vad_repository.dart";
import "package:valoqui/core/data/repositories/groq_llm_repository.dart";

// ── Sprint 2: Domain interfaces ───────────────────────────────
import "package:valoqui/core/domain/repositories/stt_repository.dart";
import "package:valoqui/core/domain/repositories/tts_repository.dart";
import "package:valoqui/core/domain/repositories/vad_repository.dart";
import "package:valoqui/core/domain/repositories/llm_repository.dart";

// ── Sprint 2: Use cases — report ──────────────────────────────
import "package:valoqui/core/domain/usecases/report/generate_report.dart";
import "package:valoqui/core/domain/usecases/report/save_session_xp.dart";

// ── Sprint 2: BLoCs ───────────────────────────────────────────
import "package:valoqui/features/speaking/bloc/speaking_bloc.dart";
import "package:valoqui/features/report/bloc/report_bloc.dart";

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

  // ── Step 4: Use cases (singletons) — Sprint 1 ────────────
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

  // ── Step 5: BLoCs (factories) — Sprint 1 ─────────────────
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

  // ─────────────────────────────────────────────────────────
  // SPRINT 2 REGISTRATIONS
  // ─────────────────────────────────────────────────────────

  // ── Step 6: Sprint 2 datasources (singletons) ────────────
  // Singletons because TTS and VAD models are expensive to load
  // and must survive across the speaking → report navigation.

  sl.registerLazySingleton<AndroidSttDatasource>(
    () => AndroidSttDatasource(),
  );

  sl.registerLazySingleton<SherpaTtsDatasource>(
    () => SherpaTtsDatasource(),
  );

  sl.registerLazySingleton<SherpaVadDatasource>(
    () => SherpaVadDatasource(),
  );

  sl.registerLazySingleton<GroqLlmDatasource>(
    () => GroqLlmDatasource(dio: sl<DioClient>().groqDio),
  );

  sl.registerLazySingleton<GeminiLlmDatasource>(
    () => GeminiLlmDatasource(dio: sl<DioClient>().geminiDio),
  );

  // ── Step 7: Sprint 2 repositories (singletons, against interfaces) ──
  sl.registerLazySingleton<SttRepository>(
    () => AndroidSttRepository(datasource: sl<AndroidSttDatasource>()),
  );

  sl.registerLazySingleton<TtsRepository>(
    () => SherpaTtsRepository(datasource: sl<SherpaTtsDatasource>()),
  );

  sl.registerLazySingleton<VadRepository>(
    () => SherpaVadRepository(datasource: sl<SherpaVadDatasource>()),
  );

  // GroqLlmRepository owns the Gemini fallback logic internally.
  // The rest of the app calls LlmRepository and never knows which
  // provider responded.
  sl.registerLazySingleton<LlmRepository>(
    () => GroqLlmRepository(
      groq: sl<GroqLlmDatasource>(),
      gemini: sl<GeminiLlmDatasource>(),
      keyStorage: sl<KeyStorageRepository>(),
    ),
  );

  // ── Step 8: Sprint 2 use cases (singletons) ───────────────
  sl.registerLazySingleton<GenerateReport>(
    () => GenerateReport(llm: sl<LlmRepository>()),
  );

  sl.registerLazySingleton<SaveSessionXp>(
    () => SaveSessionXp(userRepository: sl<UserRepository>()),
  );

  // ── Step 9: Sprint 2 BLoCs (factories) ───────────────────
  // Both are factories — a fresh BLoC per session/report.
  // They are route-scoped in app_router.dart, not app-level.

  sl.registerFactory<SpeakingBloc>(
    () => SpeakingBloc(
      stt: sl<SttRepository>(),
      tts: sl<TtsRepository>(),
      vad: sl<VadRepository>(),
      llm: sl<LlmRepository>(),
    ),
  );

  sl.registerFactory<ReportBloc>(
    () => ReportBloc(
      generateReport: sl<GenerateReport>(),
      saveSessionXp: sl<SaveSessionXp>(),
    ),
  );
}
