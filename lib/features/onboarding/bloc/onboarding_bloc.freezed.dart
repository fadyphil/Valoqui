// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState()';
}


}

/// @nodoc
class $OnboardingStateCopyWith<$Res>  {
$OnboardingStateCopyWith(OnboardingState _, $Res Function(OnboardingState) __);
}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OnboardingInitial value)?  initial,TResult Function( OnboardingLoading value)?  loading,TResult Function( GroqKeyComplete value)?  groqKeyComplete,TResult Function( GeminiStepComplete value)?  geminiStepComplete,TResult Function( OnboardingComplete value)?  complete,TResult Function( OnboardingError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OnboardingInitial() when initial != null:
return initial(_that);case OnboardingLoading() when loading != null:
return loading(_that);case GroqKeyComplete() when groqKeyComplete != null:
return groqKeyComplete(_that);case GeminiStepComplete() when geminiStepComplete != null:
return geminiStepComplete(_that);case OnboardingComplete() when complete != null:
return complete(_that);case OnboardingError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OnboardingInitial value)  initial,required TResult Function( OnboardingLoading value)  loading,required TResult Function( GroqKeyComplete value)  groqKeyComplete,required TResult Function( GeminiStepComplete value)  geminiStepComplete,required TResult Function( OnboardingComplete value)  complete,required TResult Function( OnboardingError value)  error,}){
final _that = this;
switch (_that) {
case OnboardingInitial():
return initial(_that);case OnboardingLoading():
return loading(_that);case GroqKeyComplete():
return groqKeyComplete(_that);case GeminiStepComplete():
return geminiStepComplete(_that);case OnboardingComplete():
return complete(_that);case OnboardingError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OnboardingInitial value)?  initial,TResult? Function( OnboardingLoading value)?  loading,TResult? Function( GroqKeyComplete value)?  groqKeyComplete,TResult? Function( GeminiStepComplete value)?  geminiStepComplete,TResult? Function( OnboardingComplete value)?  complete,TResult? Function( OnboardingError value)?  error,}){
final _that = this;
switch (_that) {
case OnboardingInitial() when initial != null:
return initial(_that);case OnboardingLoading() when loading != null:
return loading(_that);case GroqKeyComplete() when groqKeyComplete != null:
return groqKeyComplete(_that);case GeminiStepComplete() when geminiStepComplete != null:
return geminiStepComplete(_that);case OnboardingComplete() when complete != null:
return complete(_that);case OnboardingError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  groqKeyComplete,TResult Function()?  geminiStepComplete,TResult Function()?  complete,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OnboardingInitial() when initial != null:
return initial();case OnboardingLoading() when loading != null:
return loading();case GroqKeyComplete() when groqKeyComplete != null:
return groqKeyComplete();case GeminiStepComplete() when geminiStepComplete != null:
return geminiStepComplete();case OnboardingComplete() when complete != null:
return complete();case OnboardingError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  groqKeyComplete,required TResult Function()  geminiStepComplete,required TResult Function()  complete,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case OnboardingInitial():
return initial();case OnboardingLoading():
return loading();case GroqKeyComplete():
return groqKeyComplete();case GeminiStepComplete():
return geminiStepComplete();case OnboardingComplete():
return complete();case OnboardingError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  groqKeyComplete,TResult? Function()?  geminiStepComplete,TResult? Function()?  complete,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case OnboardingInitial() when initial != null:
return initial();case OnboardingLoading() when loading != null:
return loading();case GroqKeyComplete() when groqKeyComplete != null:
return groqKeyComplete();case GeminiStepComplete() when geminiStepComplete != null:
return geminiStepComplete();case OnboardingComplete() when complete != null:
return complete();case OnboardingError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class OnboardingInitial implements OnboardingState {
  const OnboardingInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.initial()';
}


}




/// @nodoc


class OnboardingLoading implements OnboardingState {
  const OnboardingLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.loading()';
}


}




/// @nodoc


class GroqKeyComplete implements OnboardingState {
  const GroqKeyComplete();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroqKeyComplete);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.groqKeyComplete()';
}


}




/// @nodoc


class GeminiStepComplete implements OnboardingState {
  const GeminiStepComplete();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeminiStepComplete);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.geminiStepComplete()';
}


}




/// @nodoc


class OnboardingComplete implements OnboardingState {
  const OnboardingComplete();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingComplete);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.complete()';
}


}




/// @nodoc


class OnboardingError implements OnboardingState {
  const OnboardingError({required this.message});
  

 final  String message;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingErrorCopyWith<OnboardingError> get copyWith => _$OnboardingErrorCopyWithImpl<OnboardingError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'OnboardingState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $OnboardingErrorCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory $OnboardingErrorCopyWith(OnboardingError value, $Res Function(OnboardingError) _then) = _$OnboardingErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$OnboardingErrorCopyWithImpl<$Res>
    implements $OnboardingErrorCopyWith<$Res> {
  _$OnboardingErrorCopyWithImpl(this._self, this._then);

  final OnboardingError _self;
  final $Res Function(OnboardingError) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(OnboardingError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
