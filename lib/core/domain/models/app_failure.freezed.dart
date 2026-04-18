// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppFailure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure()';
}


}

/// @nodoc
class $AppFailureCopyWith<$Res>  {
$AppFailureCopyWith(AppFailure _, $Res Function(AppFailure) __);
}


/// Adds pattern-matching-related methods to [AppFailure].
extension AppFailurePatterns on AppFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SignInCancelled value)?  signInCancelled,TResult Function( _AuthFailure value)?  authFailure,TResult Function( _UserNotFound value)?  userNotFound,TResult Function( _DatabaseFailure value)?  databaseFailure,TResult Function( _StorageFailure value)?  storageFailure,TResult Function( _InvalidApiKey value)?  invalidApiKey,TResult Function( _NetworkFailure value)?  networkFailure,TResult Function( _RateLimitFailure value)?  rateLimitFailure,TResult Function( _SttPermissionDenied value)?  sttPermissionDenied,TResult Function( _SttNotAvailable value)?  sttNotAvailable,TResult Function( _SttFailure value)?  sttFailure,TResult Function( _TtsNotInitialized value)?  ttsNotInitialized,TResult Function( _TtsFailure value)?  ttsFailure,TResult Function( _LlmFailure value)?  llmFailure,TResult Function( _LlmBothProvidersFailed value)?  llmBothProvidersFailed,TResult Function( _ReportGenerationFailed value)?  reportGenerationFailed,TResult Function( _ReportParsingFailed value)?  reportParsingFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignInCancelled() when signInCancelled != null:
return signInCancelled(_that);case _AuthFailure() when authFailure != null:
return authFailure(_that);case _UserNotFound() when userNotFound != null:
return userNotFound(_that);case _DatabaseFailure() when databaseFailure != null:
return databaseFailure(_that);case _StorageFailure() when storageFailure != null:
return storageFailure(_that);case _InvalidApiKey() when invalidApiKey != null:
return invalidApiKey(_that);case _NetworkFailure() when networkFailure != null:
return networkFailure(_that);case _RateLimitFailure() when rateLimitFailure != null:
return rateLimitFailure(_that);case _SttPermissionDenied() when sttPermissionDenied != null:
return sttPermissionDenied(_that);case _SttNotAvailable() when sttNotAvailable != null:
return sttNotAvailable(_that);case _SttFailure() when sttFailure != null:
return sttFailure(_that);case _TtsNotInitialized() when ttsNotInitialized != null:
return ttsNotInitialized(_that);case _TtsFailure() when ttsFailure != null:
return ttsFailure(_that);case _LlmFailure() when llmFailure != null:
return llmFailure(_that);case _LlmBothProvidersFailed() when llmBothProvidersFailed != null:
return llmBothProvidersFailed(_that);case _ReportGenerationFailed() when reportGenerationFailed != null:
return reportGenerationFailed(_that);case _ReportParsingFailed() when reportParsingFailed != null:
return reportParsingFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SignInCancelled value)  signInCancelled,required TResult Function( _AuthFailure value)  authFailure,required TResult Function( _UserNotFound value)  userNotFound,required TResult Function( _DatabaseFailure value)  databaseFailure,required TResult Function( _StorageFailure value)  storageFailure,required TResult Function( _InvalidApiKey value)  invalidApiKey,required TResult Function( _NetworkFailure value)  networkFailure,required TResult Function( _RateLimitFailure value)  rateLimitFailure,required TResult Function( _SttPermissionDenied value)  sttPermissionDenied,required TResult Function( _SttNotAvailable value)  sttNotAvailable,required TResult Function( _SttFailure value)  sttFailure,required TResult Function( _TtsNotInitialized value)  ttsNotInitialized,required TResult Function( _TtsFailure value)  ttsFailure,required TResult Function( _LlmFailure value)  llmFailure,required TResult Function( _LlmBothProvidersFailed value)  llmBothProvidersFailed,required TResult Function( _ReportGenerationFailed value)  reportGenerationFailed,required TResult Function( _ReportParsingFailed value)  reportParsingFailed,}){
final _that = this;
switch (_that) {
case _SignInCancelled():
return signInCancelled(_that);case _AuthFailure():
return authFailure(_that);case _UserNotFound():
return userNotFound(_that);case _DatabaseFailure():
return databaseFailure(_that);case _StorageFailure():
return storageFailure(_that);case _InvalidApiKey():
return invalidApiKey(_that);case _NetworkFailure():
return networkFailure(_that);case _RateLimitFailure():
return rateLimitFailure(_that);case _SttPermissionDenied():
return sttPermissionDenied(_that);case _SttNotAvailable():
return sttNotAvailable(_that);case _SttFailure():
return sttFailure(_that);case _TtsNotInitialized():
return ttsNotInitialized(_that);case _TtsFailure():
return ttsFailure(_that);case _LlmFailure():
return llmFailure(_that);case _LlmBothProvidersFailed():
return llmBothProvidersFailed(_that);case _ReportGenerationFailed():
return reportGenerationFailed(_that);case _ReportParsingFailed():
return reportParsingFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SignInCancelled value)?  signInCancelled,TResult? Function( _AuthFailure value)?  authFailure,TResult? Function( _UserNotFound value)?  userNotFound,TResult? Function( _DatabaseFailure value)?  databaseFailure,TResult? Function( _StorageFailure value)?  storageFailure,TResult? Function( _InvalidApiKey value)?  invalidApiKey,TResult? Function( _NetworkFailure value)?  networkFailure,TResult? Function( _RateLimitFailure value)?  rateLimitFailure,TResult? Function( _SttPermissionDenied value)?  sttPermissionDenied,TResult? Function( _SttNotAvailable value)?  sttNotAvailable,TResult? Function( _SttFailure value)?  sttFailure,TResult? Function( _TtsNotInitialized value)?  ttsNotInitialized,TResult? Function( _TtsFailure value)?  ttsFailure,TResult? Function( _LlmFailure value)?  llmFailure,TResult? Function( _LlmBothProvidersFailed value)?  llmBothProvidersFailed,TResult? Function( _ReportGenerationFailed value)?  reportGenerationFailed,TResult? Function( _ReportParsingFailed value)?  reportParsingFailed,}){
final _that = this;
switch (_that) {
case _SignInCancelled() when signInCancelled != null:
return signInCancelled(_that);case _AuthFailure() when authFailure != null:
return authFailure(_that);case _UserNotFound() when userNotFound != null:
return userNotFound(_that);case _DatabaseFailure() when databaseFailure != null:
return databaseFailure(_that);case _StorageFailure() when storageFailure != null:
return storageFailure(_that);case _InvalidApiKey() when invalidApiKey != null:
return invalidApiKey(_that);case _NetworkFailure() when networkFailure != null:
return networkFailure(_that);case _RateLimitFailure() when rateLimitFailure != null:
return rateLimitFailure(_that);case _SttPermissionDenied() when sttPermissionDenied != null:
return sttPermissionDenied(_that);case _SttNotAvailable() when sttNotAvailable != null:
return sttNotAvailable(_that);case _SttFailure() when sttFailure != null:
return sttFailure(_that);case _TtsNotInitialized() when ttsNotInitialized != null:
return ttsNotInitialized(_that);case _TtsFailure() when ttsFailure != null:
return ttsFailure(_that);case _LlmFailure() when llmFailure != null:
return llmFailure(_that);case _LlmBothProvidersFailed() when llmBothProvidersFailed != null:
return llmBothProvidersFailed(_that);case _ReportGenerationFailed() when reportGenerationFailed != null:
return reportGenerationFailed(_that);case _ReportParsingFailed() when reportParsingFailed != null:
return reportParsingFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  signInCancelled,TResult Function( String message)?  authFailure,TResult Function()?  userNotFound,TResult Function( String message)?  databaseFailure,TResult Function( String message)?  storageFailure,TResult Function()?  invalidApiKey,TResult Function( String message)?  networkFailure,TResult Function()?  rateLimitFailure,TResult Function()?  sttPermissionDenied,TResult Function()?  sttNotAvailable,TResult Function( String message)?  sttFailure,TResult Function()?  ttsNotInitialized,TResult Function( String message)?  ttsFailure,TResult Function( String message)?  llmFailure,TResult Function()?  llmBothProvidersFailed,TResult Function( String message)?  reportGenerationFailed,TResult Function()?  reportParsingFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignInCancelled() when signInCancelled != null:
return signInCancelled();case _AuthFailure() when authFailure != null:
return authFailure(_that.message);case _UserNotFound() when userNotFound != null:
return userNotFound();case _DatabaseFailure() when databaseFailure != null:
return databaseFailure(_that.message);case _StorageFailure() when storageFailure != null:
return storageFailure(_that.message);case _InvalidApiKey() when invalidApiKey != null:
return invalidApiKey();case _NetworkFailure() when networkFailure != null:
return networkFailure(_that.message);case _RateLimitFailure() when rateLimitFailure != null:
return rateLimitFailure();case _SttPermissionDenied() when sttPermissionDenied != null:
return sttPermissionDenied();case _SttNotAvailable() when sttNotAvailable != null:
return sttNotAvailable();case _SttFailure() when sttFailure != null:
return sttFailure(_that.message);case _TtsNotInitialized() when ttsNotInitialized != null:
return ttsNotInitialized();case _TtsFailure() when ttsFailure != null:
return ttsFailure(_that.message);case _LlmFailure() when llmFailure != null:
return llmFailure(_that.message);case _LlmBothProvidersFailed() when llmBothProvidersFailed != null:
return llmBothProvidersFailed();case _ReportGenerationFailed() when reportGenerationFailed != null:
return reportGenerationFailed(_that.message);case _ReportParsingFailed() when reportParsingFailed != null:
return reportParsingFailed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  signInCancelled,required TResult Function( String message)  authFailure,required TResult Function()  userNotFound,required TResult Function( String message)  databaseFailure,required TResult Function( String message)  storageFailure,required TResult Function()  invalidApiKey,required TResult Function( String message)  networkFailure,required TResult Function()  rateLimitFailure,required TResult Function()  sttPermissionDenied,required TResult Function()  sttNotAvailable,required TResult Function( String message)  sttFailure,required TResult Function()  ttsNotInitialized,required TResult Function( String message)  ttsFailure,required TResult Function( String message)  llmFailure,required TResult Function()  llmBothProvidersFailed,required TResult Function( String message)  reportGenerationFailed,required TResult Function()  reportParsingFailed,}) {final _that = this;
switch (_that) {
case _SignInCancelled():
return signInCancelled();case _AuthFailure():
return authFailure(_that.message);case _UserNotFound():
return userNotFound();case _DatabaseFailure():
return databaseFailure(_that.message);case _StorageFailure():
return storageFailure(_that.message);case _InvalidApiKey():
return invalidApiKey();case _NetworkFailure():
return networkFailure(_that.message);case _RateLimitFailure():
return rateLimitFailure();case _SttPermissionDenied():
return sttPermissionDenied();case _SttNotAvailable():
return sttNotAvailable();case _SttFailure():
return sttFailure(_that.message);case _TtsNotInitialized():
return ttsNotInitialized();case _TtsFailure():
return ttsFailure(_that.message);case _LlmFailure():
return llmFailure(_that.message);case _LlmBothProvidersFailed():
return llmBothProvidersFailed();case _ReportGenerationFailed():
return reportGenerationFailed(_that.message);case _ReportParsingFailed():
return reportParsingFailed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  signInCancelled,TResult? Function( String message)?  authFailure,TResult? Function()?  userNotFound,TResult? Function( String message)?  databaseFailure,TResult? Function( String message)?  storageFailure,TResult? Function()?  invalidApiKey,TResult? Function( String message)?  networkFailure,TResult? Function()?  rateLimitFailure,TResult? Function()?  sttPermissionDenied,TResult? Function()?  sttNotAvailable,TResult? Function( String message)?  sttFailure,TResult? Function()?  ttsNotInitialized,TResult? Function( String message)?  ttsFailure,TResult? Function( String message)?  llmFailure,TResult? Function()?  llmBothProvidersFailed,TResult? Function( String message)?  reportGenerationFailed,TResult? Function()?  reportParsingFailed,}) {final _that = this;
switch (_that) {
case _SignInCancelled() when signInCancelled != null:
return signInCancelled();case _AuthFailure() when authFailure != null:
return authFailure(_that.message);case _UserNotFound() when userNotFound != null:
return userNotFound();case _DatabaseFailure() when databaseFailure != null:
return databaseFailure(_that.message);case _StorageFailure() when storageFailure != null:
return storageFailure(_that.message);case _InvalidApiKey() when invalidApiKey != null:
return invalidApiKey();case _NetworkFailure() when networkFailure != null:
return networkFailure(_that.message);case _RateLimitFailure() when rateLimitFailure != null:
return rateLimitFailure();case _SttPermissionDenied() when sttPermissionDenied != null:
return sttPermissionDenied();case _SttNotAvailable() when sttNotAvailable != null:
return sttNotAvailable();case _SttFailure() when sttFailure != null:
return sttFailure(_that.message);case _TtsNotInitialized() when ttsNotInitialized != null:
return ttsNotInitialized();case _TtsFailure() when ttsFailure != null:
return ttsFailure(_that.message);case _LlmFailure() when llmFailure != null:
return llmFailure(_that.message);case _LlmBothProvidersFailed() when llmBothProvidersFailed != null:
return llmBothProvidersFailed();case _ReportGenerationFailed() when reportGenerationFailed != null:
return reportGenerationFailed(_that.message);case _ReportParsingFailed() when reportParsingFailed != null:
return reportParsingFailed();case _:
  return null;

}
}

}

/// @nodoc


class _SignInCancelled extends AppFailure {
  const _SignInCancelled(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignInCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.signInCancelled()';
}


}




/// @nodoc


class _AuthFailure extends AppFailure {
  const _AuthFailure({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthFailureCopyWith<_AuthFailure> get copyWith => __$AuthFailureCopyWithImpl<_AuthFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.authFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class _$AuthFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$AuthFailureCopyWith(_AuthFailure value, $Res Function(_AuthFailure) _then) = __$AuthFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$AuthFailureCopyWithImpl<$Res>
    implements _$AuthFailureCopyWith<$Res> {
  __$AuthFailureCopyWithImpl(this._self, this._then);

  final _AuthFailure _self;
  final $Res Function(_AuthFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_AuthFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UserNotFound extends AppFailure {
  const _UserNotFound(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.userNotFound()';
}


}




/// @nodoc


class _DatabaseFailure extends AppFailure {
  const _DatabaseFailure({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseFailureCopyWith<_DatabaseFailure> get copyWith => __$DatabaseFailureCopyWithImpl<_DatabaseFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.databaseFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class _$DatabaseFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$DatabaseFailureCopyWith(_DatabaseFailure value, $Res Function(_DatabaseFailure) _then) = __$DatabaseFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$DatabaseFailureCopyWithImpl<$Res>
    implements _$DatabaseFailureCopyWith<$Res> {
  __$DatabaseFailureCopyWithImpl(this._self, this._then);

  final _DatabaseFailure _self;
  final $Res Function(_DatabaseFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_DatabaseFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _StorageFailure extends AppFailure {
  const _StorageFailure({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageFailureCopyWith<_StorageFailure> get copyWith => __$StorageFailureCopyWithImpl<_StorageFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.storageFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class _$StorageFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$StorageFailureCopyWith(_StorageFailure value, $Res Function(_StorageFailure) _then) = __$StorageFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$StorageFailureCopyWithImpl<$Res>
    implements _$StorageFailureCopyWith<$Res> {
  __$StorageFailureCopyWithImpl(this._self, this._then);

  final _StorageFailure _self;
  final $Res Function(_StorageFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_StorageFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _InvalidApiKey extends AppFailure {
  const _InvalidApiKey(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvalidApiKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.invalidApiKey()';
}


}




/// @nodoc


class _NetworkFailure extends AppFailure {
  const _NetworkFailure({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkFailureCopyWith<_NetworkFailure> get copyWith => __$NetworkFailureCopyWithImpl<_NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.networkFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class _$NetworkFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$NetworkFailureCopyWith(_NetworkFailure value, $Res Function(_NetworkFailure) _then) = __$NetworkFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$NetworkFailureCopyWithImpl<$Res>
    implements _$NetworkFailureCopyWith<$Res> {
  __$NetworkFailureCopyWithImpl(this._self, this._then);

  final _NetworkFailure _self;
  final $Res Function(_NetworkFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_NetworkFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _RateLimitFailure extends AppFailure {
  const _RateLimitFailure(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RateLimitFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.rateLimitFailure()';
}


}




/// @nodoc


class _SttPermissionDenied extends AppFailure {
  const _SttPermissionDenied(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SttPermissionDenied);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.sttPermissionDenied()';
}


}




/// @nodoc


class _SttNotAvailable extends AppFailure {
  const _SttNotAvailable(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SttNotAvailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.sttNotAvailable()';
}


}




/// @nodoc


class _SttFailure extends AppFailure {
  const _SttFailure({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SttFailureCopyWith<_SttFailure> get copyWith => __$SttFailureCopyWithImpl<_SttFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SttFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.sttFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class _$SttFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$SttFailureCopyWith(_SttFailure value, $Res Function(_SttFailure) _then) = __$SttFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$SttFailureCopyWithImpl<$Res>
    implements _$SttFailureCopyWith<$Res> {
  __$SttFailureCopyWithImpl(this._self, this._then);

  final _SttFailure _self;
  final $Res Function(_SttFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_SttFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _TtsNotInitialized extends AppFailure {
  const _TtsNotInitialized(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsNotInitialized);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.ttsNotInitialized()';
}


}




/// @nodoc


class _TtsFailure extends AppFailure {
  const _TtsFailure({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TtsFailureCopyWith<_TtsFailure> get copyWith => __$TtsFailureCopyWithImpl<_TtsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TtsFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.ttsFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class _$TtsFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$TtsFailureCopyWith(_TtsFailure value, $Res Function(_TtsFailure) _then) = __$TtsFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$TtsFailureCopyWithImpl<$Res>
    implements _$TtsFailureCopyWith<$Res> {
  __$TtsFailureCopyWithImpl(this._self, this._then);

  final _TtsFailure _self;
  final $Res Function(_TtsFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_TtsFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LlmFailure extends AppFailure {
  const _LlmFailure({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LlmFailureCopyWith<_LlmFailure> get copyWith => __$LlmFailureCopyWithImpl<_LlmFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LlmFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.llmFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class _$LlmFailureCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$LlmFailureCopyWith(_LlmFailure value, $Res Function(_LlmFailure) _then) = __$LlmFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$LlmFailureCopyWithImpl<$Res>
    implements _$LlmFailureCopyWith<$Res> {
  __$LlmFailureCopyWithImpl(this._self, this._then);

  final _LlmFailure _self;
  final $Res Function(_LlmFailure) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_LlmFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LlmBothProvidersFailed extends AppFailure {
  const _LlmBothProvidersFailed(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LlmBothProvidersFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.llmBothProvidersFailed()';
}


}




/// @nodoc


class _ReportGenerationFailed extends AppFailure {
  const _ReportGenerationFailed({required this.message}): super._();
  

 final  String message;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReportGenerationFailedCopyWith<_ReportGenerationFailed> get copyWith => __$ReportGenerationFailedCopyWithImpl<_ReportGenerationFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportGenerationFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AppFailure.reportGenerationFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ReportGenerationFailedCopyWith<$Res> implements $AppFailureCopyWith<$Res> {
  factory _$ReportGenerationFailedCopyWith(_ReportGenerationFailed value, $Res Function(_ReportGenerationFailed) _then) = __$ReportGenerationFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ReportGenerationFailedCopyWithImpl<$Res>
    implements _$ReportGenerationFailedCopyWith<$Res> {
  __$ReportGenerationFailedCopyWithImpl(this._self, this._then);

  final _ReportGenerationFailed _self;
  final $Res Function(_ReportGenerationFailed) _then;

/// Create a copy of AppFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ReportGenerationFailed(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ReportParsingFailed extends AppFailure {
  const _ReportParsingFailed(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReportParsingFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AppFailure.reportParsingFailed()';
}


}




// dart format on
