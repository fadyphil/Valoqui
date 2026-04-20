import "package:flutter_test/flutter_test.dart";
import "package:fpdart/fpdart.dart";
import "package:mocktail/mocktail.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/models/session_report.dart";
import "package:valoqui/core/domain/repositories/llm_repository.dart";
import "package:valoqui/core/domain/usecases/report/generate_report.dart";

class MockLlmRepository extends Mock implements LlmRepository {}

void main() {
  late MockLlmRepository mockLlmRepository;
  late GenerateReport useCase;

  const transcript = "User: Hola";
  const userLevel = "A2";

  const validJson = '''
{
  "overall_grade": "B",
  "fluency_score": 80,
  "grammar_score": 79,
  "vocabulary_score": 85,
  "session_duration_seconds": 320,
  "active_speaking_seconds": 130,
  "spanish_word_count": 55,
  "topics_covered": ["travel"],
  "mistakes": [],
  "vocabulary_highlights": [],
  "fluency_note": "Good flow.",
  "grammar_note": "Small tense misses.",
  "vocabulary_note": "Nice range.",
  "encouragement": "Keep practicing!",
  "xp_breakdown": {
    "time_speaking_xp": 16,
    "spanish_words_xp": 10,
    "grammar_bonus_xp": 5,
    "vocabulary_bonus_xp": 5,
    "session_completion_xp": 25,
    "first_session_today_xp": 0,
    "total_xp": 61
  }
}
''';

  setUp(() {
    mockLlmRepository = MockLlmRepository();
    useCase = GenerateReport(llm: mockLlmRepository);
  });

  test(
    "returns parsed report on first successful valid JSON response",
    () async {
      when(
        () => mockLlmRepository.generateReport(
          transcript: transcript,
          userLevel: userLevel,
        ),
      ).thenAnswer((_) async => const Right<AppFailure, String>(validJson));

      final result = await useCase.execute(
        transcript: transcript,
        userLevel: userLevel,
      );

      final report = result.fold<SessionReport?>((_) => null, (r) => r);

      expect(report, isNotNull);
      expect(report!.overallGrade, "B");
      expect(report.xpBreakdown.totalXp, 61);
      verify(
        () => mockLlmRepository.generateReport(
          transcript: transcript,
          userLevel: userLevel,
        ),
      ).called(1);
    },
  );

  test("strips markdown fences before JSON parsing", () async {
    const fencedJson = "```json\n$validJson\n```";
    when(
      () => mockLlmRepository.generateReport(
        transcript: transcript,
        userLevel: userLevel,
      ),
    ).thenAnswer((_) async => const Right<AppFailure, String>(fencedJson));

    final result = await useCase.execute(
      transcript: transcript,
      userLevel: userLevel,
    );

    expect(result.isRight(), isTrue);
    verify(
      () => mockLlmRepository.generateReport(
        transcript: transcript,
        userLevel: userLevel,
      ),
    ).called(1);
  });

  test(
    "retries parse failures and succeeds on a later valid response",
    () async {
      var callCount = 0;
      when(
        () => mockLlmRepository.generateReport(
          transcript: transcript,
          userLevel: userLevel,
        ),
      ).thenAnswer((_) async {
        callCount += 1;
        if (callCount < 3) {
          return const Right<AppFailure, String>("{ invalid json }");
        }
        return const Right<AppFailure, String>(validJson);
      });

      final result = await useCase.execute(
        transcript: transcript,
        userLevel: userLevel,
      );

      expect(result.isRight(), isTrue);
      expect(callCount, 3);
    },
  );

  test("returns parsing failure after three invalid JSON attempts", () async {
    when(
      () => mockLlmRepository.generateReport(
        transcript: transcript,
        userLevel: userLevel,
      ),
    ).thenAnswer(
      (_) async => const Right<AppFailure, String>("{ invalid json }"),
    );

    final result = await useCase.execute(
      transcript: transcript,
      userLevel: userLevel,
    );

    expect(
      result,
      const Left<AppFailure, SessionReport>(AppFailure.reportParsingFailed()),
    );
    verify(
      () => mockLlmRepository.generateReport(
        transcript: transcript,
        userLevel: userLevel,
      ),
    ).called(3);
  });

  test("returns llm failure immediately without retries", () async {
    const failure = AppFailure.llmBothProvidersFailed();
    when(
      () => mockLlmRepository.generateReport(
        transcript: transcript,
        userLevel: userLevel,
      ),
    ).thenAnswer((_) async => const Left<AppFailure, String>(failure));

    final result = await useCase.execute(
      transcript: transcript,
      userLevel: userLevel,
    );

    expect(result, const Left<AppFailure, SessionReport>(failure));
    verify(
      () => mockLlmRepository.generateReport(
        transcript: transcript,
        userLevel: userLevel,
      ),
    ).called(1);
  });
}
