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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SignInCancelled value)?  signInCancelled,TResult Function( _AuthFailure value)?  authFailure,TResult Function( _UserNotFound value)?  userNotFound,TResult Function( _DatabaseFailure value)?  databaseFailure,TResult Function( _StorageFailure value)?  storageFailure,TResult Function( _InvalidApiKey value)?  invalidApiKey,TResult Function( _NetworkFailure value)?  networkFailure,TResult Function( _RateLimitFailure value)?  rateLimitFailure,required TResult orElse(),}){
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
return rateLimitFailure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SignInCancelled value)  signInCancelled,required TResult Function( _AuthFailure value)  authFailure,required TResult Function( _UserNotFound value)  userNotFound,required TResult Function( _DatabaseFailure value)  databaseFailure,required TResult Function( _StorageFailure value)  storageFailure,required TResult Function( _InvalidApiKey value)  invalidApiKey,required TResult Function( _NetworkFailure value)  networkFailure,required TResult Function( _RateLimitFailure value)  rateLimitFailure,}){
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
return rateLimitFailure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SignInCancelled value)?  signInCancelled,TResult? Function( _AuthFailure value)?  authFailure,TResult? Function( _UserNotFound value)?  userNotFound,TResult? Function( _DatabaseFailure value)?  databaseFailure,TResult? Function( _StorageFailure value)?  storageFailure,TResult? Function( _InvalidApiKey value)?  invalidApiKey,TResult? Function( _NetworkFailure value)?  networkFailure,TResult? Function( _RateLimitFailure value)?  rateLimitFailure,}){
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
return rateLimitFailure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  signInCancelled,TResult Function( String message)?  authFailure,TResult Function()?  userNotFound,TResult Function( String message)?  databaseFailure,TResult Function( String message)?  storageFailure,TResult Function()?  invalidApiKey,TResult Function( String message)?  networkFailure,TResult Function()?  rateLimitFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignInCancelled() when signInCancelled != null:
return signInCancelled();case _AuthFailure() when authFailure != null:
return authFailure(_that.message);case _UserNotFound() when userNotFound != null:
return userNotFound();case _DatabaseFailure() when databaseFailure != null:
return databaseFailure(_that.message);case _StorageFailure() when storageFailure != null:
return storageFailure(_that.message);case _InvalidApiKey() when invalidApiKey != null:
return invalidApiKey();case _NetworkFailure() when networkFailure != null:
return networkFailure(_that.message);case _RateLimitFailure() when rateLimitFailure != null:
return rateLimitFailure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  signInCancelled,required TResult Function( String message)  authFailure,required TResult Function()  userNotFound,required TResult Function( String message)  databaseFailure,required TResult Function( String message)  storageFailure,required TResult Function()  invalidApiKey,required TResult Function( String message)  networkFailure,required TResult Function()  rateLimitFailure,}) {final _that = this;
switch (_that) {
case _SignInCancelled():
return signInCancelled();case _AuthFailure():
return authFailure(_that.message);case _UserNotFound():
return userNotFound();case _DatabaseFailure():
return databaseFailure(_that.message);case _StorageFailure():
return storageFailure(_that.message);case _InvalidApiKey():
return invalidApiKey();case _NetworkFailure():
return networkFailure(_that.message);case _RateLimitFailure():
return rateLimitFailure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  signInCancelled,TResult? Function( String message)?  authFailure,TResult? Function()?  userNotFound,TResult? Function( String message)?  databaseFailure,TResult? Function( String message)?  storageFailure,TResult? Function()?  invalidApiKey,TResult? Function( String message)?  networkFailure,TResult? Function()?  rateLimitFailure,}) {final _that = this;
switch (_that) {
case _SignInCancelled() when signInCancelled != null:
return signInCancelled();case _AuthFailure() when authFailure != null:
return authFailure(_that.message);case _UserNotFound() when userNotFound != null:
return userNotFound();case _DatabaseFailure() when databaseFailure != null:
return databaseFailure(_that.message);case _StorageFailure() when storageFailure != null:
return storageFailure(_that.message);case _InvalidApiKey() when invalidApiKey != null:
return invalidApiKey();case _NetworkFailure() when networkFailure != null:
return networkFailure(_that.message);case _RateLimitFailure() when rateLimitFailure != null:
return rateLimitFailure();case _:
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




// dart format on
