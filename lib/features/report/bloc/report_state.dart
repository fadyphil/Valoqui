// lib/features/report/bloc/report_state.dart

part of 'report_bloc.dart';

@freezed
sealed class ReportState with _$ReportState {
  const factory ReportState.initial() = ReportInitial;

  /// Report generation API call in progress.
  /// Carries session metadata so the loading screen can show real numbers.
  const factory ReportState.generating({
    required Duration totalDuration,
    required Duration activeSpeakingTime,
  }) = ReportGenerating;

  /// Report parsed and XP saved successfully.
  const factory ReportState.loaded({
    required SessionReport report,
    required Duration totalDuration,
    required Duration activeSpeakingTime,
  }) = ReportLoaded;

  /// All 3 generation attempts failed — XP was saved via client-side fallback.
  const factory ReportState.fallback({
    required int totalXp,
    required String reason,
  }) = ReportFallback;

  /// Fatal error — XP could not be saved either.
  const factory ReportState.error({required String message}) = ReportError;
}
