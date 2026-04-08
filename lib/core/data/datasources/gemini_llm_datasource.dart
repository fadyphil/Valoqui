// lib/core/data/datasources/gemini_llm_datasource.dart
//
// Gemini 2.0 Flash fallback LLM datasource.
// The API shape differs from Groq's OpenAI-compatible format:
//   - roles: "user" / "model" (not "assistant")
//   - message structure: contents[].parts[].text
//   - system prompt: separate "system_instruction" field
//
// GroqLlmRepository handles the decision of when to call this.
// This datasource only knows how to call Gemini.

import "dart:async";
import "dart:convert";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";

class GeminiLlmDatasource {
  final Dio _dio;

  GeminiLlmDatasource({required Dio dio}) : _dio = dio;

  // ── Streaming conversation response ───────────────────
  Stream<Either<AppFailure, String>> streamResponse({
    required List<ConversationMessage> messages,
    required String systemPrompt,
    int maxTokens = 120,
  }) async* {
    try {
      // Gemini uses "model" for assistant role
      final contents = messages
          .map(
            (m) => {
              "role": m.role == "assistant" ? "model" : "user",
              "parts": [
                {"text": m.content},
              ],
            },
          )
          .toList();

      final response = await _dio.post<ResponseBody>(
        "models/gemini-2.0-flash:streamGenerateContent",
        queryParameters: {"alt": "sse"},
        data: {
          "system_instruction": {
            "parts": [
              {"text": systemPrompt},
            ],
          },
          "contents": contents,
          "generationConfig": {
            "maxOutputTokens": maxTokens,
            "temperature": 0.8,
          },
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream;
      final lineBuffer = StringBuffer();

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);

        for (final char in text.split("")) {
          if (char == "\n") {
            final line = lineBuffer.toString().trim();
            lineBuffer.clear();

            if (!line.startsWith("data: ")) continue;

            final data = line.substring(6).trim();
            if (data.isEmpty || data == "[DONE]") continue;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;

              // Cast candidates explicitly
              final candidates = json["candidates"] as List<dynamic>?;
              if (candidates == null || candidates.isEmpty) continue;

              // Cast the first candidate to Map before accessing nested fields
              final firstCandidate = candidates[0] as Map<String, dynamic>;
              final content =
                  firstCandidate['content'] as Map<String, dynamic>?;
              if (content == null) continue;

              final parts = content['parts'] as List<dynamic>?;
              if (parts == null || parts.isEmpty) continue;

              // Cast the first part to Map before accessing 'text'
              final firstPart = parts[0] as Map<String, dynamic>;
              final token = firstPart['text'] as String?;
              if (token != null && token.isNotEmpty) {
                yield right(token);
              }
            } catch (_) {
              // Malformed chunk — skip
            }
          } else {
            lineBuffer.write(char);
          }
        }
      }
    } on DioException catch (e) {
      yield left(
        AppFailure.llmFailure(
          message:
              "Gemini stream error [${e.response?.statusCode}]: ${e.message}",
        ),
      );
    } catch (e) {
      yield left(AppFailure.llmFailure(message: "Gemini stream error: $e"));
    }
  }

  // ── Single call for report generation ─────────────────
  Future<Either<AppFailure, String>> generateReport({
    required String prompt,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        "models/gemini-2.0-flash:generateContent",
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {"maxOutputTokens": 2000, "temperature": 0.3},
        },
      );

      final candidates = response.data?["candidates"] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return left(
          const AppFailure.reportGenerationFailed(
            message: "Gemini returned empty response",
          ),
        );
      }

      final firstCandidate = candidates[0] as Map<String, dynamic>;

      final content = firstCandidate["content"] as Map<String, dynamic>?;
      // This is explicit type casting for following the the Defesive i/o never trust the API , this allows for gracefull  error or mismatch handling
      final parts = content?["parts"] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return left(
          const AppFailure.reportGenerationFailed(
            message: "Gemini response missing 'parts' field",
          ),
        );
      }

      final firstPart = parts[0] as Map<String, dynamic>;
      final text = firstPart["text"] as String? ?? '';
      return right(text);
    } on DioException catch (e) {
      return left(
        AppFailure.reportGenerationFailed(
          message:
              "Gemini report error [${e.response?.statusCode}]: ${e.message}",
        ),
      );
    } catch (e) {
      debugPrint("[Gemini] generateReport error: $e");
      return left(
        AppFailure.reportGenerationFailed(message: "Gemini report error: $e"),
      );
    }
  }
}
