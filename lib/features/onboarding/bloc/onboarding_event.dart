// lib/features/onboarding/bloc/onboarding_event.dart

part of "onboarding_bloc.dart";

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class CheckOnboardingStatusEvent extends OnboardingEvent {
  const CheckOnboardingStatusEvent();
}

class SubmitGroqKey extends OnboardingEvent {
  final String key;
  final String uid;
  const SubmitGroqKey({required this.key, required this.uid});

  @override
  List<Object?> get props => [key, uid];
}

class SubmitGeminiKey extends OnboardingEvent {
  final String key;
  final String uid;
  const SubmitGeminiKey({required this.key, required this.uid});

  @override
  List<Object?> get props => [key, uid];
}

class SkipGeminiKey extends OnboardingEvent {
  const SkipGeminiKey();
}

class SubmitLevel extends OnboardingEvent {
  final String level;
  final String uid;
  const SubmitLevel({required this.level, required this.uid});

  @override
  List<Object?> get props => [level, uid];
}
