// lib/features/onboarding/bloc/onboarding_bloc.dart

import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import 'package:valoqui/core/domain/usecases/onboarding/check_onboarding_status.dart';
import 'package:valoqui/core/domain/usecases/onboarding/mark_onboarding_complete.dart';
import 'package:valoqui/core/domain/usecases/onboarding/save_gemini_key.dart';
import 'package:valoqui/core/domain/usecases/onboarding/save_groq_key.dart';
import 'package:valoqui/core/domain/usecases/user/update_user_level.dart';

part "onboarding_bloc.freezed.dart";
part "onboarding_event.dart";
part "onboarding_state.dart";

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final CheckOnboardingStatus _checkOnboardingStatus;
  final SaveGroqKey _saveGroqKey;
  final SaveGeminiKey _saveGeminiKey;
  final MarkOnboardingComplete _markOnboardingComplete;
  final UpdateUserLevel _updateUserLevel;

  OnboardingBloc({
    required CheckOnboardingStatus checkOnboardingStatus,
    required SaveGroqKey saveGroqKey,
    required SaveGeminiKey saveGeminiKey,
    required MarkOnboardingComplete markOnboardingComplete,
    required UpdateUserLevel updateUserLevel,
  }) : _checkOnboardingStatus = checkOnboardingStatus,
       _saveGroqKey = saveGroqKey,
       _saveGeminiKey = saveGeminiKey,
       _markOnboardingComplete = markOnboardingComplete,
       _updateUserLevel = updateUserLevel,
       super(const OnboardingState.initial()) {
    on<CheckOnboardingStatusEvent>(_onCheckStatus);
    on<SubmitGroqKey>(_onSubmitGroqKey);
    on<SubmitGeminiKey>(_onSubmitGeminiKey);
    on<SkipGeminiKey>(_onSkipGeminiKey);
    on<SubmitLevel>(_onSubmitLevel);
  }

  Future<void> _onCheckStatus(
    CheckOnboardingStatusEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingState.loading());
    final result = await _checkOnboardingStatus.execute();
    result.fold(
      (failure) => emit(OnboardingState.error(message: failure.message)),
      (isComplete) => isComplete
          ? emit(const OnboardingState.complete())
          : emit(const OnboardingState.initial()),
    );
  }

  Future<void> _onSubmitGroqKey(
    SubmitGroqKey event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingState.loading());
    final result = await _saveGroqKey.execute(event.uid, event.key);
    result.fold(
      (failure) => emit(OnboardingState.error(message: failure.message)),
      (_) => emit(const OnboardingState.groqKeyComplete()),
    );
  }

  Future<void> _onSubmitGeminiKey(
    SubmitGeminiKey event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingState.loading());
    final result = await _saveGeminiKey.execute(event.uid, event.key);
    result.fold(
      (failure) => emit(OnboardingState.error(message: failure.message)),
      (_) => emit(const OnboardingState.geminiStepComplete()),
    );
  }

  void _onSkipGeminiKey(SkipGeminiKey event, Emitter<OnboardingState> emit) {
    emit(const OnboardingState.geminiStepComplete());
  }

  Future<void> _onSubmitLevel(
    SubmitLevel event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingState.loading());

    final levelResult = await _updateUserLevel.execute(event.uid, event.level);

    await levelResult.fold(
      (failure) async => emit(OnboardingState.error(message: failure.message)),
      (_) async {
        final completeResult = await _markOnboardingComplete.execute();
        completeResult.fold(
          (failure) => emit(OnboardingState.error(message: failure.message)),
          (_) => emit(const OnboardingState.complete()),
        );
      },
    );
  }
}
