// lib/features/report/bloc/report_bloc.dart
//
// Receives a completed session, generates a graded report via the LLM,
// saves XP to Firestore, and emits the result.
//
// The GenerateReport use case handles retry (3 attempts) and JSON parsing.
// This BLoC handles the fallback XP calculation when all attempts fail
// and the Firestore write in all cases.

import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:valoqui/core/domain/models/conversation_message.dart";
import "package:valoqui/core/domain/models/session_report.dart";
import "package:valoqui/core/domain/usecases/report/generate_report.dart";
import "package:valoqui/core/domain/usecases/report/save_session_xp.dart";

part "report_event.dart";
part "report_state.dart";
part "report_bloc.freezed.dart";

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GenerateReport _generateReport;
  final SaveSessionXp _saveSessionXp;

  ReportBloc({
    required GenerateReport generateReport,
    required SaveSessionXp saveSessionXp,
  }) : _generateReport = generateReport,
       _saveSessionXp = saveSessionXp,
       super(const ReportState.initial()) {
    on<GenerateReportEvent>(_onGenerateReport);
  }

  Future<void> _onGenerateReport(
    GenerateReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportState.generating());

    // Format transcript as plain text for the grading prompt
    final transcriptText = event.transcript
        .map((m) => "${m.isUser ? "User" : "Lucia"}: ${m.content}")
        .join("\n");

    // GenerateReport use case handles retry (3 attempts) + JSON parsing
    final reportResult = await _generateReport.execute(
      transcript: transcriptText,
      userLevel: event.userCefrLevel,
    );

    await reportResult.fold(
      // ── Report generation failed ────────────────────────
      (failure) async {
        // Still save XP using client-side fallback calculation
        final fallbackXp = _calculateFallbackXp(event.activeSpeakingTime);
        await _saveSessionXp.execute(uid: event.userId, xp: fallbackXp);

        emit(
          ReportState.fallback(totalXp: fallbackXp, reason: failure.message),
        );
      },

      // ── Report generated successfully ───────────────────
      (report) async {
        final xp = report.xpBreakdown.totalXp;
        final saveResult = await _saveSessionXp.execute(
          uid: event.userId,
          xp: xp,
        );

        // XP save failure is non-fatal — show the report anyway.
        // The user can see their score even if Firestore had a hiccup.
        // We do not surface the XP save error to avoid ruining the
        // post-session experience.
        saveResult.fold(
          (_) {}, // swallow — non-fatal
          (_) {},
        );

        emit(
          ReportState.loaded(
            report: report,
            totalDuration: event.totalDuration,
            activeSpeakingTime: event.activeSpeakingTime,
          ),
        );
      },
    );
  }

  /// Fallback XP calculation used when the LLM report cannot be generated.
  /// Based on active speaking time only — time_speaking_xp + session_completion_xp.
  int _calculateFallbackXp(Duration activeSpeaking) {
    final minutes = activeSpeaking.inMinutes;
    final timeSpeakingXp = minutes * 8; // 8 XP per minute
    const sessionCompletionXp = 25;
    return timeSpeakingXp + sessionCompletionXp;
  }
}
