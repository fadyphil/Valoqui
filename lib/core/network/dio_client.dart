// lib/core/network/dio_client.dart
//
// Change from previous version:
// Constructor now takes KeyStorageRepository instead of
// SecureStorageService, since SecureStorageService no longer exists.
// The ApiKeyInterceptor is updated accordingly.

import "package:dio/dio.dart";
import "package:valoqui/core/domain/repositories/key_storage_repository.dart";
import "package:valoqui/core/network/interceptors/api_key_interceptor.dart";
import "package:valoqui/core/network/interceptors/logging_interceptor.dart";

class DioClient {
  late final Dio groqDio;
  late final Dio geminiDio;

  DioClient({required KeyStorageRepository keyStorage}) {
    groqDio = _buildDio(
      baseUrl: "https://api.groq.com/openai/v1/",
      keyStorage: keyStorage,
      keyType: ApiKeyType.groq,
    );

    geminiDio = _buildDio(
      baseUrl: "https://generativelanguage.googleapis.com/v1beta/",
      keyStorage: keyStorage,
      keyType: ApiKeyType.gemini,
    );
  }

  Dio _buildDio({
    required String baseUrl,
    required KeyStorageRepository keyStorage,
    required ApiKeyType keyType,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.addAll([
      ApiKeyInterceptor(keyStorage: keyStorage, keyType: keyType),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
