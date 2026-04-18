// lib/features/home/bloc/home_state.dart

part of "home_bloc.dart";

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({required AppUser profile}) = HomeLoaded;
  const factory HomeState.error({required String message}) = HomeError;
}
