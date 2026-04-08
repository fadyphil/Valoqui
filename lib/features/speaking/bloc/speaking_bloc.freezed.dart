// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'speaking_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpeakingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpeakingState()';
}


}

/// @nodoc
class $SpeakingStateCopyWith<$Res>  {
$SpeakingStateCopyWith(SpeakingState _, $Res Function(SpeakingState) __);
}


/// Adds pattern-matching-related methods to [SpeakingState].
extension SpeakingStatePatterns on SpeakingState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SpeakingInitial value)?  initial,TResult Function( SpeakingInitializing value)?  initializing,TResult Function( SpeakingActive value)?  active,TResult Function( SpeakingEnded value)?  ended,TResult Function( SpeakingError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SpeakingInitial() when initial != null:
return initial(_that);case SpeakingInitializing() when initializing != null:
return initializing(_that);case SpeakingActive() when active != null:
return active(_that);case SpeakingEnded() when ended != null:
return ended(_that);case SpeakingError() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SpeakingInitial value)  initial,required TResult Function( SpeakingInitializing value)  initializing,required TResult Function( SpeakingActive value)  active,required TResult Function( SpeakingEnded value)  ended,required TResult Function( SpeakingError value)  error,}){
final _that = this;
switch (_that) {
case SpeakingInitial():
return initial(_that);case SpeakingInitializing():
return initializing(_that);case SpeakingActive():
return active(_that);case SpeakingEnded():
return ended(_that);case SpeakingError():
return error(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SpeakingInitial value)?  initial,TResult? Function( SpeakingInitializing value)?  initializing,TResult? Function( SpeakingActive value)?  active,TResult? Function( SpeakingEnded value)?  ended,TResult? Function( SpeakingError value)?  error,}){
final _that = this;
switch (_that) {
case SpeakingInitial() when initial != null:
return initial(_that);case SpeakingInitializing() when initializing != null:
return initializing(_that);case SpeakingActive() when active != null:
return active(_that);case SpeakingEnded() when ended != null:
return ended(_that);case SpeakingError() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  initializing,TResult Function( List<ConversationMessage> transcript,  ConversationPhase phase,  MicMode micMode,  Duration elapsed,  Duration activeSpeakingTime,  String currentLuciaBuffer,  String? partialUserTranscript,  double amplitude,  String? errorMessage)?  active,TResult Function( List<ConversationMessage> transcript,  Duration totalDuration,  Duration activeSpeakingTime,  String userId,  String userCefrLevel)?  ended,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SpeakingInitial() when initial != null:
return initial();case SpeakingInitializing() when initializing != null:
return initializing();case SpeakingActive() when active != null:
return active(_that.transcript,_that.phase,_that.micMode,_that.elapsed,_that.activeSpeakingTime,_that.currentLuciaBuffer,_that.partialUserTranscript,_that.amplitude,_that.errorMessage);case SpeakingEnded() when ended != null:
return ended(_that.transcript,_that.totalDuration,_that.activeSpeakingTime,_that.userId,_that.userCefrLevel);case SpeakingError() when error != null:
return error(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  initializing,required TResult Function( List<ConversationMessage> transcript,  ConversationPhase phase,  MicMode micMode,  Duration elapsed,  Duration activeSpeakingTime,  String currentLuciaBuffer,  String? partialUserTranscript,  double amplitude,  String? errorMessage)  active,required TResult Function( List<ConversationMessage> transcript,  Duration totalDuration,  Duration activeSpeakingTime,  String userId,  String userCefrLevel)  ended,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SpeakingInitial():
return initial();case SpeakingInitializing():
return initializing();case SpeakingActive():
return active(_that.transcript,_that.phase,_that.micMode,_that.elapsed,_that.activeSpeakingTime,_that.currentLuciaBuffer,_that.partialUserTranscript,_that.amplitude,_that.errorMessage);case SpeakingEnded():
return ended(_that.transcript,_that.totalDuration,_that.activeSpeakingTime,_that.userId,_that.userCefrLevel);case SpeakingError():
return error(_that.message);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  initializing,TResult? Function( List<ConversationMessage> transcript,  ConversationPhase phase,  MicMode micMode,  Duration elapsed,  Duration activeSpeakingTime,  String currentLuciaBuffer,  String? partialUserTranscript,  double amplitude,  String? errorMessage)?  active,TResult? Function( List<ConversationMessage> transcript,  Duration totalDuration,  Duration activeSpeakingTime,  String userId,  String userCefrLevel)?  ended,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SpeakingInitial() when initial != null:
return initial();case SpeakingInitializing() when initializing != null:
return initializing();case SpeakingActive() when active != null:
return active(_that.transcript,_that.phase,_that.micMode,_that.elapsed,_that.activeSpeakingTime,_that.currentLuciaBuffer,_that.partialUserTranscript,_that.amplitude,_that.errorMessage);case SpeakingEnded() when ended != null:
return ended(_that.transcript,_that.totalDuration,_that.activeSpeakingTime,_that.userId,_that.userCefrLevel);case SpeakingError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SpeakingInitial implements SpeakingState {
  const SpeakingInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakingInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpeakingState.initial()';
}


}




/// @nodoc


class SpeakingInitializing implements SpeakingState {
  const SpeakingInitializing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakingInitializing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SpeakingState.initializing()';
}


}




/// @nodoc


class SpeakingActive implements SpeakingState {
  const SpeakingActive({required final  List<ConversationMessage> transcript, required this.phase, required this.micMode, required this.elapsed, required this.activeSpeakingTime, required this.currentLuciaBuffer, this.partialUserTranscript, this.amplitude = 0.0, this.errorMessage}): _transcript = transcript;
  

/// Full transcript displayed in the scroll view.
 final  List<ConversationMessage> _transcript;
/// Full transcript displayed in the scroll view.
 List<ConversationMessage> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

/// Current phase — drives mic button visual and waveform visibility.
 final  ConversationPhase phase;
/// Current mic input mode.
 final  MicMode micMode;
/// Session wall-clock time since SessionStarted.
 final  Duration elapsed;
/// Accumulated time the user spent actually speaking.
 final  Duration activeSpeakingTime;
/// Tokens currently accumulating for Lucia's current response.
/// Cleared once the full response is committed to transcript.
 final  String currentLuciaBuffer;
/// STT partial result shown live in the user bubble while speaking.
/// Null when the user is not speaking.
 final  String? partialUserTranscript;
/// The current amplitude of the user's speech.
@JsonKey() final  double amplitude;
/// Non-fatal error message shown as a toast (e.g. network hiccup).
/// Null when there is no error.
 final  String? errorMessage;

/// Create a copy of SpeakingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeakingActiveCopyWith<SpeakingActive> get copyWith => _$SpeakingActiveCopyWithImpl<SpeakingActive>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakingActive&&const DeepCollectionEquality().equals(other._transcript, _transcript)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.micMode, micMode) || other.micMode == micMode)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.activeSpeakingTime, activeSpeakingTime) || other.activeSpeakingTime == activeSpeakingTime)&&(identical(other.currentLuciaBuffer, currentLuciaBuffer) || other.currentLuciaBuffer == currentLuciaBuffer)&&(identical(other.partialUserTranscript, partialUserTranscript) || other.partialUserTranscript == partialUserTranscript)&&(identical(other.amplitude, amplitude) || other.amplitude == amplitude)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transcript),phase,micMode,elapsed,activeSpeakingTime,currentLuciaBuffer,partialUserTranscript,amplitude,errorMessage);

@override
String toString() {
  return 'SpeakingState.active(transcript: $transcript, phase: $phase, micMode: $micMode, elapsed: $elapsed, activeSpeakingTime: $activeSpeakingTime, currentLuciaBuffer: $currentLuciaBuffer, partialUserTranscript: $partialUserTranscript, amplitude: $amplitude, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SpeakingActiveCopyWith<$Res> implements $SpeakingStateCopyWith<$Res> {
  factory $SpeakingActiveCopyWith(SpeakingActive value, $Res Function(SpeakingActive) _then) = _$SpeakingActiveCopyWithImpl;
@useResult
$Res call({
 List<ConversationMessage> transcript, ConversationPhase phase, MicMode micMode, Duration elapsed, Duration activeSpeakingTime, String currentLuciaBuffer, String? partialUserTranscript, double amplitude, String? errorMessage
});




}
/// @nodoc
class _$SpeakingActiveCopyWithImpl<$Res>
    implements $SpeakingActiveCopyWith<$Res> {
  _$SpeakingActiveCopyWithImpl(this._self, this._then);

  final SpeakingActive _self;
  final $Res Function(SpeakingActive) _then;

/// Create a copy of SpeakingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transcript = null,Object? phase = null,Object? micMode = null,Object? elapsed = null,Object? activeSpeakingTime = null,Object? currentLuciaBuffer = null,Object? partialUserTranscript = freezed,Object? amplitude = null,Object? errorMessage = freezed,}) {
  return _then(SpeakingActive(
transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ConversationMessage>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ConversationPhase,micMode: null == micMode ? _self.micMode : micMode // ignore: cast_nullable_to_non_nullable
as MicMode,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,activeSpeakingTime: null == activeSpeakingTime ? _self.activeSpeakingTime : activeSpeakingTime // ignore: cast_nullable_to_non_nullable
as Duration,currentLuciaBuffer: null == currentLuciaBuffer ? _self.currentLuciaBuffer : currentLuciaBuffer // ignore: cast_nullable_to_non_nullable
as String,partialUserTranscript: freezed == partialUserTranscript ? _self.partialUserTranscript : partialUserTranscript // ignore: cast_nullable_to_non_nullable
as String?,amplitude: null == amplitude ? _self.amplitude : amplitude // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SpeakingEnded implements SpeakingState {
  const SpeakingEnded({required final  List<ConversationMessage> transcript, required this.totalDuration, required this.activeSpeakingTime, required this.userId, required this.userCefrLevel}): _transcript = transcript;
  

 final  List<ConversationMessage> _transcript;
 List<ConversationMessage> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

 final  Duration totalDuration;
 final  Duration activeSpeakingTime;
 final  String userId;
 final  String userCefrLevel;

/// Create a copy of SpeakingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeakingEndedCopyWith<SpeakingEnded> get copyWith => _$SpeakingEndedCopyWithImpl<SpeakingEnded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakingEnded&&const DeepCollectionEquality().equals(other._transcript, _transcript)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.activeSpeakingTime, activeSpeakingTime) || other.activeSpeakingTime == activeSpeakingTime)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userCefrLevel, userCefrLevel) || other.userCefrLevel == userCefrLevel));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_transcript),totalDuration,activeSpeakingTime,userId,userCefrLevel);

@override
String toString() {
  return 'SpeakingState.ended(transcript: $transcript, totalDuration: $totalDuration, activeSpeakingTime: $activeSpeakingTime, userId: $userId, userCefrLevel: $userCefrLevel)';
}


}

/// @nodoc
abstract mixin class $SpeakingEndedCopyWith<$Res> implements $SpeakingStateCopyWith<$Res> {
  factory $SpeakingEndedCopyWith(SpeakingEnded value, $Res Function(SpeakingEnded) _then) = _$SpeakingEndedCopyWithImpl;
@useResult
$Res call({
 List<ConversationMessage> transcript, Duration totalDuration, Duration activeSpeakingTime, String userId, String userCefrLevel
});




}
/// @nodoc
class _$SpeakingEndedCopyWithImpl<$Res>
    implements $SpeakingEndedCopyWith<$Res> {
  _$SpeakingEndedCopyWithImpl(this._self, this._then);

  final SpeakingEnded _self;
  final $Res Function(SpeakingEnded) _then;

/// Create a copy of SpeakingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transcript = null,Object? totalDuration = null,Object? activeSpeakingTime = null,Object? userId = null,Object? userCefrLevel = null,}) {
  return _then(SpeakingEnded(
transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ConversationMessage>,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as Duration,activeSpeakingTime: null == activeSpeakingTime ? _self.activeSpeakingTime : activeSpeakingTime // ignore: cast_nullable_to_non_nullable
as Duration,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userCefrLevel: null == userCefrLevel ? _self.userCefrLevel : userCefrLevel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SpeakingError implements SpeakingState {
  const SpeakingError({required this.message});
  

 final  String message;

/// Create a copy of SpeakingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeakingErrorCopyWith<SpeakingError> get copyWith => _$SpeakingErrorCopyWithImpl<SpeakingError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeakingError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SpeakingState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SpeakingErrorCopyWith<$Res> implements $SpeakingStateCopyWith<$Res> {
  factory $SpeakingErrorCopyWith(SpeakingError value, $Res Function(SpeakingError) _then) = _$SpeakingErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SpeakingErrorCopyWithImpl<$Res>
    implements $SpeakingErrorCopyWith<$Res> {
  _$SpeakingErrorCopyWithImpl(this._self, this._then);

  final SpeakingError _self;
  final $Res Function(SpeakingError) _then;

/// Create a copy of SpeakingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SpeakingError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
