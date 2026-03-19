// test/mocks/mock_services.dart

import "package:mocktail/mocktail.dart";
import "package:valoqui/core/services/auth_service.dart";
import "package:valoqui/core/services/firestore_service.dart";
import "package:valoqui/core/services/secure_storage_service.dart";

class MockAuthService extends Mock implements AuthService {}

class MockFirestoreService extends Mock implements FirestoreService {}

class MockSecureStorage extends Mock implements SecureStorageService {}
