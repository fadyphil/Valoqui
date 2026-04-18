// lib/core/network/interceptors/api_key_interceptor.dart
//
// Change from previous version:
// Takes KeyStorageRepository instead of SecureStorageService.
// Uses the Either result safely — if the key read fails,
// the request proceeds without an auth header and Groq/Gemini
// will return a 401, which the FallbackInterceptor handles (Sprint 2).

import "package:dio/dio.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";

enum ApiKeyType { groq, gemini }

class ApiKeyInterceptor extends Interceptor {
  final KeyStorageRepository _keyStorage;
  final ApiKeyType _keyType;

  ApiKeyInterceptor({
    required KeyStorageRepository keyStorage,
    required ApiKeyType keyType,
  }) : _keyStorage = keyStorage,
       _keyType = keyType;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final result = _keyType == ApiKeyType.groq
        ? await _keyStorage.getGroqKey()
        : await _keyStorage.getGeminiKey();

    result.fold(
      (_) {}, // Storage error — proceed without header, API will 401
      (key) {
        if (key != null && key.isNotEmpty) {
          options.headers["Authorization"] = "Bearer $key";
        }
      },
    );

    handler.next(options);
  }
}
