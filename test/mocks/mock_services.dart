// test/mocks/mock_services.dart

import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/usecases/auth/sign_in_with_google.dart";
import "package:valoqui/core/domain/usecases/auth/sign_out.dart";
import "package:valoqui/core/domain/usecases/auth/watch_auth_state.dart";
import "package:valoqui/core/domain/usecases/onboarding/check_onboarding_status.dart";
import "package:valoqui/core/domain/usecases/onboarding/mark_onboarding_complete.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_gemini_key.dart";
import "package:valoqui/core/domain/usecases/onboarding/save_groq_key.dart";
import "package:valoqui/core/domain/usecases/user/update_user_level.dart";
import "package:valoqui/core/domain/usecases/user/watch_user_profile.dart";
import "package:valoqui/core/data/datasources/firebase_auth_datasource.dart";
import "package:valoqui/core/data/datasources/firestore_datasource.dart";
import "package:valoqui/core/data/datasources/secure_storage_datasource.dart";
import "package:valoqui/core/domain/repositories/auth_repository.dart";
import "package:valoqui/core/domain/repositories/user_repository.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";

// ── Datasource Mocks ───────────────────────────────────
class MockFirebaseAuthDatasource extends Mock
    implements FirebaseAuthDatasource {}

class MockFirestoreDatasource extends Mock implements FirestoreDatasource {}

class MockSecureStorageDatasource extends Mock
    implements SecureStorageDatasource {}

// ── Repository Mocks ───────────────────────────────────
class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockKeyStorageRepository extends Mock implements KeyStorageRepository {}

// ── Auth UseCase Mocks ─────────────────────────────────
class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSignOut extends Mock implements SignOut {}

class MockWatchAuthState extends Mock implements WatchAuthState {}

// ── Onboarding UseCase Mocks ───────────────────────────
class MockCheckOnboardingStatus extends Mock implements CheckOnboardingStatus {}

class MockMarkOnboardingComplete extends Mock
    implements MarkOnboardingComplete {}

class MockSaveGeminiKey extends Mock implements SaveGeminiKey {}

class MockSaveGroqKey extends Mock implements SaveGroqKey {}

// ── User UseCase Mocks ─────────────────────────────────
class MockUpdateUserLevel extends Mock implements UpdateUserLevel {}

class MockWatchUserProfile extends Mock implements WatchUserProfile {}
