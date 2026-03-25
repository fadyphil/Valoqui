// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReportState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReportState()';
}


}

/// @nodoc
class $ReportStateCopyWith<$Res>  {
$ReportStateCopyWith(ReportState _, $Res Function(ReportState) __);
}


/// Adds pattern-matching-related methods to [ReportState].
extension ReportStatePatterns on ReportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReportInitial value)?  initial,TResult Function( ReportGenerating value)?  generating,TResult Function( ReportLoaded value)?  loaded,TResult Function( ReportFallback value)?  fallback,TResult Function( ReportError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReportInitial() when initial != null:
return initial(_that);case ReportGenerating() when generating != null:
return generating(_that);case ReportLoaded() when loaded != null:
return loaded(_that);case ReportFallback() when fallback != null:
return fallback(_that);case ReportError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReportInitial value)  initial,required TResult Function( ReportGenerating value)  generating,required TResult Function( ReportLoaded value)  loaded,required TResult Function( ReportFallback value)  fallback,required TResult Function( ReportError value)  error,}){
final _that = this;
switch (_that) {
case ReportInitial():
return initial(_that);case ReportGenerating():
return generating(_that);case ReportLoaded():
return loaded(_that);case ReportFallback():
return fallback(_that);case ReportError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReportInitial value)?  initial,TResult? Function( ReportGenerating value)?  generating,TResult? Function( ReportLoaded value)?  loaded,TResult? Function( ReportFallback value)?  fallback,TResult? Function( ReportError value)?  error,}){
final _that = this;
switch (_that) {
case ReportInitial() when initial != null:
return initial(_that);case ReportGenerating() when generating != null:
return generating(_that);case ReportLoaded() when loaded != null:
return loaded(_that);case ReportFallback() when fallback != null:
return fallback(_that);case ReportError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  generating,TResult Function( SessionReport report,  Duration totalDuration,  Duration activeSpeakingTime)?  loaded,TResult Function( int totalXp,  String reason)?  fallback,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReportInitial() when initial != null:
return initial();case ReportGenerating() when generating != null:
return generating();case ReportLoaded() when loaded != null:
return loaded(_that.report,_that.totalDuration,_that.activeSpeakingTime);case ReportFallback() when fallback != null:
return fallback(_that.totalXp,_that.reason);case ReportError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  generating,required TResult Function( SessionReport report,  Duration totalDuration,  Duration activeSpeakingTime)  loaded,required TResult Function( int totalXp,  String reason)  fallback,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ReportInitial():
return initial();case ReportGenerating():
return generating();case ReportLoaded():
return loaded(_that.report,_that.totalDuration,_that.activeSpeakingTime);case ReportFallback():
return fallback(_that.totalXp,_that.reason);case ReportError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  generating,TResult? Function( SessionReport report,  Duration totalDuration,  Duration activeSpeakingTime)?  loaded,TResult? Function( int totalXp,  String reason)?  fallback,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ReportInitial() when initial != null:
return initial();case ReportGenerating() when generating != null:
return generating();case ReportLoaded() when loaded != null:
return loaded(_that.report,_that.totalDuration,_that.activeSpeakingTime);case ReportFallback() when fallback != null:
return fallback(_that.totalXp,_that.reason);case ReportError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ReportInitial implements ReportState {
  const ReportInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReportState.initial()';
}


}




/// @nodoc


class ReportGenerating implements ReportState {
  const ReportGenerating();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportGenerating);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReportState.generating()';
}


}




/// @nodoc


class ReportLoaded implements ReportState {
  const ReportLoaded({required this.report, required this.totalDuration, required this.activeSpeakingTime});
  

 final  SessionReport report;
 final  Duration totalDuration;
 final  Duration activeSpeakingTime;

/// Create a copy of ReportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportLoadedCopyWith<ReportLoaded> get copyWith => _$ReportLoadedCopyWithImpl<ReportLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportLoaded&&(identical(other.report, report) || other.report == report)&&(identical(other.totalDuration, totalDuration) || other.totalDuration == totalDuration)&&(identical(other.activeSpeakingTime, activeSpeakingTime) || other.activeSpeakingTime == activeSpeakingTime));
}


@override
int get hashCode => Object.hash(runtimeType,report,totalDuration,activeSpeakingTime);

@override
String toString() {
  return 'ReportState.loaded(report: $report, totalDuration: $totalDuration, activeSpeakingTime: $activeSpeakingTime)';
}


}

/// @nodoc
abstract mixin class $ReportLoadedCopyWith<$Res> implements $ReportStateCopyWith<$Res> {
  factory $ReportLoadedCopyWith(ReportLoaded value, $Res Function(ReportLoaded) _then) = _$ReportLoadedCopyWithImpl;
@useResult
$Res call({
 SessionReport report, Duration totalDuration, Duration activeSpeakingTime
});


$SessionReportCopyWith<$Res> get report;

}
/// @nodoc
class _$ReportLoadedCopyWithImpl<$Res>
    implements $ReportLoadedCopyWith<$Res> {
  _$ReportLoadedCopyWithImpl(this._self, this._then);

  final ReportLoaded _self;
  final $Res Function(ReportLoaded) _then;

/// Create a copy of ReportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? report = null,Object? totalDuration = null,Object? activeSpeakingTime = null,}) {
  return _then(ReportLoaded(
report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as SessionReport,totalDuration: null == totalDuration ? _self.totalDuration : totalDuration // ignore: cast_nullable_to_non_nullable
as Duration,activeSpeakingTime: null == activeSpeakingTime ? _self.activeSpeakingTime : activeSpeakingTime // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

/// Create a copy of ReportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionReportCopyWith<$Res> get report {
  
  return $SessionReportCopyWith<$Res>(_self.report, (value) {
    return _then(_self.copyWith(report: value));
  });
}
}

/// @nodoc


class ReportFallback implements ReportState {
  const ReportFallback({required this.totalXp, required this.reason});
  

 final  int totalXp;
 final  String reason;

/// Create a copy of ReportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportFallbackCopyWith<ReportFallback> get copyWith => _$ReportFallbackCopyWithImpl<ReportFallback>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportFallback&&(identical(other.totalXp, totalXp) || other.totalXp == totalXp)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,totalXp,reason);

@override
String toString() {
  return 'ReportState.fallback(totalXp: $totalXp, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ReportFallbackCopyWith<$Res> implements $ReportStateCopyWith<$Res> {
  factory $ReportFallbackCopyWith(ReportFallback value, $Res Function(ReportFallback) _then) = _$ReportFallbackCopyWithImpl;
@useResult
$Res call({
 int totalXp, String reason
});




}
/// @nodoc
class _$ReportFallbackCopyWithImpl<$Res>
    implements $ReportFallbackCopyWith<$Res> {
  _$ReportFallbackCopyWithImpl(this._self, this._then);

  final ReportFallback _self;
  final $Res Function(ReportFallback) _then;

/// Create a copy of ReportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? totalXp = null,Object? reason = null,}) {
  return _then(ReportFallback(
totalXp: null == totalXp ? _self.totalXp : totalXp // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReportError implements ReportState {
  const ReportError({required this.message});
  

 final  String message;

/// Create a copy of ReportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReportErrorCopyWith<ReportError> get copyWith => _$ReportErrorCopyWithImpl<ReportError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReportError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ReportState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ReportErrorCopyWith<$Res> implements $ReportStateCopyWith<$Res> {
  factory $ReportErrorCopyWith(ReportError value, $Res Function(ReportError) _then) = _$ReportErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ReportErrorCopyWithImpl<$Res>
    implements $ReportErrorCopyWith<$Res> {
  _$ReportErrorCopyWithImpl(this._self, this._then);

  final ReportError _self;
  final $Res Function(ReportError) _then;

/// Create a copy of ReportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ReportError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
