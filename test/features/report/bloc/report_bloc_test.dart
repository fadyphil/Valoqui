import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:valoqui/core/domain/models/app_failure.dart';
import 'package:valoqui/core/domain/models/conversation_message.dart';
import 'package:valoqui/core/domain/models/session_report.dart';
import 'package:valoqui/core/domain/usecases/report/generate_report.dart';
import 'package:valoqui/core/domain/usecases/report/save_session_xp.dart';
import 'package:valoqui/features/report/bloc/report_bloc.dart';

class MockGenerateReport extends Mock implements GenerateReport {}

class MockSaveSessionXp extends Mock implements SaveSessionXp {}

void main() {
  late ReportBloc reportBloc;
  late MockGenerateReport mockGenerateReport;
  late MockSaveSessionXp mockSaveSessionXp;

  const tTotalDuration = Duration(minutes: 5);
  const tActiveSpeakingTime = Duration(minutes: 2);
  const tUserId = 'user123';
  const tUserCefrLevel = 'A2';

  final tTranscript = <ConversationMessage>[
    ConversationMessage(
      role: 'user',
      content: 'Hola',
      timestamp: DateTime(2023),
    ),
    ConversationMessage(
      role: 'assistant',
      content: 'Hola, ¿cómo estás?',
      timestamp: DateTime(2023),
    ),
  ];
  const tTranscriptText = 'User: Hola\nLucia: Hola, ¿cómo estás?';

  const tXpBreakdown = XpBreakdown(
    timeSpeakingXp: 16,
    spanishWordsXp: 10,
    grammarBonusXp: 5,
    vocabularyBonusXp: 5,
    sessionCompletionXp: 25,
    firstSessionTodayXp: 0,
    totalXp: 61,
  );

  const tReport = SessionReport(
    overallGrade: 'B',
    fluencyScore: 80,
    grammarScore: 85,
    vocabularyScore: 80,
    sessionDurationSeconds: 300,
    activeSpeakingSeconds: 120,
    spanishWordCount: 50,
    topicsCovered: ['Greetings'],
    mistakes: [],
    vocabularyHighlights: [],
    fluencyNote: 'Good',
    grammarNote: 'Good',
    vocabularyNote: 'Good',
    encouragement: 'Keep it up!',
    xpBreakdown: tXpBreakdown,
  );

  setUp(() {
    mockGenerateReport = MockGenerateReport();
    mockSaveSessionXp = MockSaveSessionXp();

    reportBloc = ReportBloc(
      generateReport: mockGenerateReport,
      saveSessionXp: mockSaveSessionXp,
    );
  });

  tearDown(() {
    reportBloc.close();
  });

  group('ReportBloc', () {
    test('initial state should be ReportState.initial()', () {
      expect(reportBloc.state, const ReportState.initial());
    });

    blocTest<ReportBloc, ReportState>(
      'emits [generating, loaded] when report generation succeeds',
      build: () {
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer((_) async => const Right(tReport));
        when(
          () =>
              mockSaveSessionXp.execute(uid: tUserId, xp: tXpBreakdown.totalXp),
        ).thenAnswer((_) async => const Right(null));
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
        ),
        const ReportState.loaded(
          report: tReport,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
        ),
      ],
      verify: (_) {
        verify(
          () =>
              mockSaveSessionXp.execute(uid: tUserId, xp: tXpBreakdown.totalXp),
        ).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'emits [generating, loaded] even if saving XP fails (swallows error)',
      build: () {
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer((_) async => const Right(tReport));
        when(
          () =>
              mockSaveSessionXp.execute(uid: tUserId, xp: tXpBreakdown.totalXp),
        ).thenAnswer(
          (_) async =>
              const Left(AppFailure.databaseFailure(message: 'DB Error')),
        );
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
        ),
        const ReportState.loaded(
          report: tReport,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
        ),
      ],
      verify: (_) {
        verify(
          () =>
              mockSaveSessionXp.execute(uid: tUserId, xp: tXpBreakdown.totalXp),
        ).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'emits [generating, fallback] when report generation fails but fallback saves',
      build: () {
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AppFailure.reportGenerationFailed(message: 'Failed')),
        );

        // Fallback XP = (2 min * 8) + 25 = 16 + 25 = 41
        when(
          () => mockSaveSessionXp.execute(uid: tUserId, xp: 41),
        ).thenAnswer((_) async => const Right(null));
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
        ),
        const ReportState.fallback(totalXp: 41, reason: 'Failed'),
      ],
      verify: (_) {
        verify(() => mockSaveSessionXp.execute(uid: tUserId, xp: 41)).called(1);
      },
    );
  });

  // ── Add to existing ReportBloc test file ──────────────────────────────

  group('_calculateFallbackXp (pure function)', () {
    blocTest<ReportBloc, ReportState>(
      'calculates fallback XP as (minutes * 8) + 25 for 0 minutes',
      build: () {
        // ✅ Use exact formatted transcript + userLevel
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AppFailure.reportGenerationFailed(message: 'Failed')),
        );

        when(
          () => mockSaveSessionXp.execute(uid: tUserId, xp: 25),
        ).thenAnswer((_) async => const Right(null));
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: Duration.zero,
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: Duration.zero,
        ),
        const ReportState.fallback(totalXp: 25, reason: 'Failed'),
      ],
      verify: (_) {
        verify(() => mockSaveSessionXp.execute(uid: tUserId, xp: 25)).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'calculates fallback XP as (minutes * 8) + 25 for 10 minutes',
      build: () {
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AppFailure.reportGenerationFailed(message: 'Failed')),
        );

        when(
          () => mockSaveSessionXp.execute(uid: tUserId, xp: 105),
        ).thenAnswer((_) async => const Right(null));
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: const Duration(minutes: 10),
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: Duration(minutes: 10),
        ),
        const ReportState.fallback(totalXp: 105, reason: 'Failed'),
      ],
      verify: (_) {
        verify(
          () => mockSaveSessionXp.execute(uid: tUserId, xp: 105),
        ).called(1);
      },
    );

    blocTest<ReportBloc, ReportState>(
      'truncates partial minutes in fallback XP calculation',
      build: () {
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AppFailure.reportGenerationFailed(message: 'Failed')),
        );

        when(
          () => mockSaveSessionXp.execute(uid: tUserId, xp: 33),
        ).thenAnswer((_) async => const Right(null));
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: const Duration(minutes: 1, seconds: 59),
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: Duration(minutes: 1, seconds: 59),
        ),
        const ReportState.fallback(totalXp: 33, reason: 'Failed'),
      ],
    );
  });
  group('AppFailure subtype handling', () {
    blocTest<ReportBloc, ReportState>(
      'propagates networkFailure message in fallback state',
      build: () {
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AppFailure.networkFailure(message: 'No internet')),
        );

        when(
          () => mockSaveSessionXp.execute(uid: tUserId, xp: 41),
        ).thenAnswer((_) async => const Right(null));
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
        ),
        const ReportState.fallback(totalXp: 41, reason: 'No internet'),
      ],
    );

    blocTest<ReportBloc, ReportState>(
      'propagates llmBothProvidersFailed message in fallback state',
      build: () {
        const failure = AppFailure.llmBothProvidersFailed();
        when(
          () => mockGenerateReport.execute(
            transcript: tTranscriptText,
            userLevel: tUserCefrLevel,
          ),
        ).thenAnswer((_) async => const Left(failure));

        when(
          () => mockSaveSessionXp.execute(uid: tUserId, xp: 41),
        ).thenAnswer((_) async => const Right(null));
        return reportBloc;
      },
      act: (bloc) => bloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      ),
      expect: () => [
        const ReportState.generating(
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
        ),
        const ReportState.fallback(
          totalXp: 41,
          reason:
              'Both AI providers are unavailable. Try again in a few minutes.',
        ),
      ],
    );
  });
  group('State equality (freezed)', () {
    test('ReportState.loaded uses value equality', () {
      const s1 = ReportState.loaded(
        report: tReport,
        totalDuration: tTotalDuration,
        activeSpeakingTime: tActiveSpeakingTime,
      );
      const s2 = ReportState.loaded(
        report: tReport,
        totalDuration: tTotalDuration,
        activeSpeakingTime: tActiveSpeakingTime,
      );
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('ReportState.fallback uses value equality', () {
      const s1 = ReportState.fallback(totalXp: 41, reason: 'Test');
      const s2 = ReportState.fallback(totalXp: 41, reason: 'Test');
      expect(s1, equals(s2));
    });

    test('ReportState variants are not equal across types', () {
      const generating = ReportState.generating(
        totalDuration: tTotalDuration,
        activeSpeakingTime: tActiveSpeakingTime,
      );
      const loaded = ReportState.loaded(
        report: tReport,
        totalDuration: tTotalDuration,
        activeSpeakingTime: tActiveSpeakingTime,
      );
      expect(generating, isNot(equals(loaded)));
    });
  });

  group('close()', () {
    test('closes cleanly without errors', () async {
      final completer = Completer<Either<AppFailure, SessionReport>>();

      // ✅ Use exact named parameters for mock
      when(
        () => mockGenerateReport.execute(
          transcript: tTranscriptText,
          userLevel: tUserCefrLevel,
        ),
      ).thenAnswer((_) => completer.future);

      reportBloc.add(
        GenerateReportEvent(
          transcript: tTranscript,
          totalDuration: tTotalDuration,
          activeSpeakingTime: tActiveSpeakingTime,
          userId: tUserId,
          userCefrLevel: tUserCefrLevel,
        ),
      );
      await Future.microtask(() {});

      expect(() => reportBloc.close(), returnsNormally);
    });
  });
}
