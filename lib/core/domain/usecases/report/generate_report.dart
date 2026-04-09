// lib/core/domain/usecases/report/generate_report.dart
//
// Calls LlmRepository.generateReport, parses the JSON response into a
// SessionReport, and retries up to 3 times on parse failure.
//
// This use case is stateless — registered as a singleton in service_locator.

import "dart:convert";
import "package:fpdart/fpdart.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/session_report.dart";
import "package:valoqui/core/domain/repositories/llm_repository.dart";

class GenerateReport {
  final LlmRepository _llm;

  const GenerateReport({required LlmRepository llm}) : _llm = llm;

  /// [transcript] — full session transcript, both sides, formatted as:
  ///   "User: ...\nLucia: ...\nUser: ..."
  /// [userLevel] — CEFR level string, e.g. "A2"
  Future<Either<AppFailure, SessionReport>> execute({
    required String transcript,
    required String userLevel,
  }) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      final result = await _llm.generateReport(
        transcript: transcript,
        userLevel: userLevel,
      );

      final parsed = result.flatMap(_parse);

      if (parsed.isRight()) return parsed;

      // On last attempt return whatever failure we have
      if (attempt == 3) {
        return parsed.fold(left, right);
      }

      // Exponential back-off before retry (1s, 2s)
      await Future<void>.delayed(Duration(seconds: attempt));
    }

    // Unreachable — loop above always returns on attempt 3
    return left(const AppFailure.reportParsingFailed());
  }

  Either<AppFailure, SessionReport> _parse(String raw) {
    try {
      // Strip markdown fences the LLM occasionally adds despite instructions
      final cleaned = raw
          .replaceAll(RegExp(r"```json"), "")
          .replaceAll(RegExp(r"```"), "")
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return right(SessionReport.fromJson(json));
    } on Exception catch (_) {
      return left(const AppFailure.reportParsingFailed());
    }
  }
}
