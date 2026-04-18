// lib/core/network/interceptors/logging_interceptor.dart

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint("[DIO] --> ${options.method} ${options.path}");
    }
    handler.next(options);
  }

  @override
  void onResponse(
    //The Semantics of Types — Using the Right Name Dart's type system is a communication tool. Every use of that vocabulary should be precise.
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint(
        "[DIO] <-- ${response.statusCode} ${response.requestOptions.path}",
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        "[DIO] ERROR ${err.response?.statusCode} ${err.requestOptions.path}",
      );
      debugPrint("[DIO] ${err.message}");
    }
    handler.next(err);
  }
}
