// lib/features/onboarding/bloc/onboarding_state.dart

part of "onboarding_bloc.dart";

@freezed
sealed class OnboardingState with _$OnboardingState {
  const factory OnboardingState.initial() = OnboardingInitial;
  const factory OnboardingState.loading() = OnboardingLoading;
  const factory OnboardingState.groqKeyComplete() = GroqKeyComplete;
  const factory OnboardingState.geminiStepComplete() = GeminiStepComplete;
  const factory OnboardingState.complete() = OnboardingComplete;
  const factory OnboardingState.error({required String message}) =
      OnboardingError;
}
