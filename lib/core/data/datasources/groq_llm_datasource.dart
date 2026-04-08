// lib/core/data/datasources/groq_llm_datasource.dart
//
// Handles all Groq API calls:
//   - streamResponse: streaming chat completions (SSE) for conversation
//   - generateReport: single blocking call for post-session grading
//
// This datasource does NOT know about Gemini fallback.
// Fallback logic lives in GroqLlmRepository, which wraps both datasources.

import "dart:async";
import "dart:convert";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";

class GroqLlmDatasource {
  final Dio _dio;

  GroqLlmDatasource({required Dio dio}) : _dio = dio;

  // ── Streaming conversation response ───────────────────
  // Parses the Groq SSE (Server-Sent Events) stream token by token.
  // Each SSE line looks like:  data: {"choices":[{"delta":{"content":"Hola"}}]}
  // The stream ends with:      data: [DONE]
  Stream<Either<AppFailure, String>> streamResponse({
    required List<ConversationMessage> messages,
    required String systemPrompt,
    int maxTokens = 120,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        "chat/completions",
        data: {
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            ...messages.map((m) => {"role": m.role, "content": m.content}),
          ],
          "stream": true,
          "max_tokens": maxTokens,
          "temperature": 0.8,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {"Accept": "text/event-stream"},
        ),
      );

      final stream = response.data!.stream;

      // Incomplete lines accumulate here until a newline is received.
      // This handles the case where a chunk boundary splits an SSE line.
      final lineBuffer = StringBuffer();

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);

        for (final char in text.split("")) {
          if (char == "\n") {
            final line = lineBuffer.toString().trim();
            lineBuffer.clear();

            if (!line.startsWith("data: ")) continue;

            final data = line.substring(6).trim();
            if (data == "[DONE]") return;
            if (data.isEmpty) continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;

              // Cast choices explicitly
              final choices = json['choices'] as List<dynamic>?;
              if (choices == null || choices.isEmpty) continue;

              // Cast first choice to Map before nested access
              final firstChoice = choices[0] as Map<String, dynamic>;
              final delta = firstChoice['delta'] as Map<String, dynamic>?;
              if (delta == null) continue;

              final token = delta['content'] as String?;
              if (token != null && token.isNotEmpty) {
                yield right(token);
              }
            } catch (_) {
              // Malformed JSON chunk — skip silently
            }
          } else {
            lineBuffer.write(char);
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        yield left(const AppFailure.rateLimitFailure());
      } else {
        yield left(
          AppFailure.llmFailure(
            message:
                "Groq stream error [${e.response?.statusCode}]: ${e.message}",
          ),
        );
      }
    } catch (e) {
      yield left(AppFailure.llmFailure(message: "Groq stream error: $e"));
    }
  }

  // ── Single call for report generation ─────────────────
  // Not streamed — we need the complete JSON before parsing.
  // temperature: 0.3 for more deterministic, well-formatted JSON output.
  Future<Either<AppFailure, String>> generateReport({
    required String prompt,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "chat/completions",
        data: {
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "stream": false,
          "max_tokens": 2000,
          "temperature": 0.3,
        },
      );

      final choices = response.data?["choices"] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return left(
          const AppFailure.reportGenerationFailed(
            message: "Groq returned empty response",
          ),
        );
      }

      // Explicit casts to avoid dynamic calls
      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      if (message == null) {
        return left(
          const AppFailure.reportGenerationFailed(
            message: "Groq response missing 'message' field",
          ),
        );
      }
      final content = message['content'] as String? ?? '';

      return right(content);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        return left(const AppFailure.rateLimitFailure());
      }
      return left(
        AppFailure.reportGenerationFailed(
          message:
              "Groq report error [${e.response?.statusCode}]: ${e.message}",
        ),
      );
    } catch (e) {
      debugPrint("[Groq] generateReport error: $e");
      return left(
        AppFailure.reportGenerationFailed(message: "Groq report error: $e"),
      );
    }
  }
}
