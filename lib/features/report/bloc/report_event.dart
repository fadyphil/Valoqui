// lib/features/report/bloc/report_event.dart

part of "report_bloc.dart";

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

/// Fired immediately when the report route mounts.
/// ReportBloc starts grading as soon as it receives this event.
///
/// Named GenerateReportEvent (not GenerateReport) to avoid collision
/// with the GenerateReport use case class imported in report_bloc.dart.
class GenerateReportEvent extends ReportEvent {
  final List<ConversationMessage> transcript;
  final Duration totalDuration;
  final Duration activeSpeakingTime;
  final String userId;
  final String userCefrLevel;

  const GenerateReportEvent({
    required this.transcript,
    required this.totalDuration,
    required this.activeSpeakingTime,
    required this.userId,
    required this.userCefrLevel,
  });

  @override
  List<Object?> get props => [userId, totalDuration];
}
