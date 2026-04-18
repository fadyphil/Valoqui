// lib/features/home/bloc/home_event.dart

part of "home_bloc.dart";

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

// Renamed from WatchUserProfile to WatchProfile to avoid
// conflicting with the use case class name in the same file
class WatchProfile extends HomeEvent {
  final String uid;
  const WatchProfile(this.uid);

  @override
  List<Object?> get props => [uid];
}
