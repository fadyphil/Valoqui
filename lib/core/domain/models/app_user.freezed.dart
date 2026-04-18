// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppUser {

 String get uid; String get displayName; String get email; String get currentCefrLevel; int get currentXP; bool get groqKeyConfigured; bool get geminiKeyConfigured; int get streakDays; int get totalSessionCount; int get totalSpeakingSeconds;
/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUserCopyWith<AppUser> get copyWith => _$AppUserCopyWithImpl<AppUser>(this as AppUser, _$identity);

  /// Serializes this AppUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.currentCefrLevel, currentCefrLevel) || other.currentCefrLevel == currentCefrLevel)&&(identical(other.currentXP, currentXP) || other.currentXP == currentXP)&&(identical(other.groqKeyConfigured, groqKeyConfigured) || other.groqKeyConfigured == groqKeyConfigured)&&(identical(other.geminiKeyConfigured, geminiKeyConfigured) || other.geminiKeyConfigured == geminiKeyConfigured)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&(identical(other.totalSessionCount, totalSessionCount) || other.totalSessionCount == totalSessionCount)&&(identical(other.totalSpeakingSeconds, totalSpeakingSeconds) || other.totalSpeakingSeconds == totalSpeakingSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,displayName,email,currentCefrLevel,currentXP,groqKeyConfigured,geminiKeyConfigured,streakDays,totalSessionCount,totalSpeakingSeconds);

@override
String toString() {
  return 'AppUser(uid: $uid, displayName: $displayName, email: $email, currentCefrLevel: $currentCefrLevel, currentXP: $currentXP, groqKeyConfigured: $groqKeyConfigured, geminiKeyConfigured: $geminiKeyConfigured, streakDays: $streakDays, totalSessionCount: $totalSessionCount, totalSpeakingSeconds: $totalSpeakingSeconds)';
}


}

/// @nodoc
abstract mixin class $AppUserCopyWith<$Res>  {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) _then) = _$AppUserCopyWithImpl;
@useResult
$Res call({
 String uid, String displayName, String email, String currentCefrLevel, int currentXP, bool groqKeyConfigured, bool geminiKeyConfigured, int streakDays, int totalSessionCount, int totalSpeakingSeconds
});




}
/// @nodoc
class _$AppUserCopyWithImpl<$Res>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._self, this._then);

  final AppUser _self;
  final $Res Function(AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? displayName = null,Object? email = null,Object? currentCefrLevel = null,Object? currentXP = null,Object? groqKeyConfigured = null,Object? geminiKeyConfigured = null,Object? streakDays = null,Object? totalSessionCount = null,Object? totalSpeakingSeconds = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,currentCefrLevel: null == currentCefrLevel ? _self.currentCefrLevel : currentCefrLevel // ignore: cast_nullable_to_non_nullable
as String,currentXP: null == currentXP ? _self.currentXP : currentXP // ignore: cast_nullable_to_non_nullable
as int,groqKeyConfigured: null == groqKeyConfigured ? _self.groqKeyConfigured : groqKeyConfigured // ignore: cast_nullable_to_non_nullable
as bool,geminiKeyConfigured: null == geminiKeyConfigured ? _self.geminiKeyConfigured : geminiKeyConfigured // ignore: cast_nullable_to_non_nullable
as bool,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,totalSessionCount: null == totalSessionCount ? _self.totalSessionCount : totalSessionCount // ignore: cast_nullable_to_non_nullable
as int,totalSpeakingSeconds: null == totalSpeakingSeconds ? _self.totalSpeakingSeconds : totalSpeakingSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUser].
extension AppUserPatterns on AppUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUser value)  $default,){
final _that = this;
switch (_that) {
case _AppUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUser value)?  $default,){
final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String displayName,  String email,  String currentCefrLevel,  int currentXP,  bool groqKeyConfigured,  bool geminiKeyConfigured,  int streakDays,  int totalSessionCount,  int totalSpeakingSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.displayName,_that.email,_that.currentCefrLevel,_that.currentXP,_that.groqKeyConfigured,_that.geminiKeyConfigured,_that.streakDays,_that.totalSessionCount,_that.totalSpeakingSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String displayName,  String email,  String currentCefrLevel,  int currentXP,  bool groqKeyConfigured,  bool geminiKeyConfigured,  int streakDays,  int totalSessionCount,  int totalSpeakingSeconds)  $default,) {final _that = this;
switch (_that) {
case _AppUser():
return $default(_that.uid,_that.displayName,_that.email,_that.currentCefrLevel,_that.currentXP,_that.groqKeyConfigured,_that.geminiKeyConfigured,_that.streakDays,_that.totalSessionCount,_that.totalSpeakingSeconds);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String displayName,  String email,  String currentCefrLevel,  int currentXP,  bool groqKeyConfigured,  bool geminiKeyConfigured,  int streakDays,  int totalSessionCount,  int totalSpeakingSeconds)?  $default,) {final _that = this;
switch (_that) {
case _AppUser() when $default != null:
return $default(_that.uid,_that.displayName,_that.email,_that.currentCefrLevel,_that.currentXP,_that.groqKeyConfigured,_that.geminiKeyConfigured,_that.streakDays,_that.totalSessionCount,_that.totalSpeakingSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUser extends AppUser {
  const _AppUser({required this.uid, required this.displayName, required this.email, this.currentCefrLevel = "A1", this.currentXP = 0, this.groqKeyConfigured = false, this.geminiKeyConfigured = false, this.streakDays = 0, this.totalSessionCount = 0, this.totalSpeakingSeconds = 0}): super._();
  factory _AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

@override final  String uid;
@override final  String displayName;
@override final  String email;
@override@JsonKey() final  String currentCefrLevel;
@override@JsonKey() final  int currentXP;
@override@JsonKey() final  bool groqKeyConfigured;
@override@JsonKey() final  bool geminiKeyConfigured;
@override@JsonKey() final  int streakDays;
@override@JsonKey() final  int totalSessionCount;
@override@JsonKey() final  int totalSpeakingSeconds;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUserCopyWith<_AppUser> get copyWith => __$AppUserCopyWithImpl<_AppUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUser&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.currentCefrLevel, currentCefrLevel) || other.currentCefrLevel == currentCefrLevel)&&(identical(other.currentXP, currentXP) || other.currentXP == currentXP)&&(identical(other.groqKeyConfigured, groqKeyConfigured) || other.groqKeyConfigured == groqKeyConfigured)&&(identical(other.geminiKeyConfigured, geminiKeyConfigured) || other.geminiKeyConfigured == geminiKeyConfigured)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&(identical(other.totalSessionCount, totalSessionCount) || other.totalSessionCount == totalSessionCount)&&(identical(other.totalSpeakingSeconds, totalSpeakingSeconds) || other.totalSpeakingSeconds == totalSpeakingSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,displayName,email,currentCefrLevel,currentXP,groqKeyConfigured,geminiKeyConfigured,streakDays,totalSessionCount,totalSpeakingSeconds);

@override
String toString() {
  return 'AppUser(uid: $uid, displayName: $displayName, email: $email, currentCefrLevel: $currentCefrLevel, currentXP: $currentXP, groqKeyConfigured: $groqKeyConfigured, geminiKeyConfigured: $geminiKeyConfigured, streakDays: $streakDays, totalSessionCount: $totalSessionCount, totalSpeakingSeconds: $totalSpeakingSeconds)';
}


}

/// @nodoc
abstract mixin class _$AppUserCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$AppUserCopyWith(_AppUser value, $Res Function(_AppUser) _then) = __$AppUserCopyWithImpl;
@override @useResult
$Res call({
 String uid, String displayName, String email, String currentCefrLevel, int currentXP, bool groqKeyConfigured, bool geminiKeyConfigured, int streakDays, int totalSessionCount, int totalSpeakingSeconds
});




}
/// @nodoc
class __$AppUserCopyWithImpl<$Res>
    implements _$AppUserCopyWith<$Res> {
  __$AppUserCopyWithImpl(this._self, this._then);

  final _AppUser _self;
  final $Res Function(_AppUser) _then;

/// Create a copy of AppUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? displayName = null,Object? email = null,Object? currentCefrLevel = null,Object? currentXP = null,Object? groqKeyConfigured = null,Object? geminiKeyConfigured = null,Object? streakDays = null,Object? totalSessionCount = null,Object? totalSpeakingSeconds = null,}) {
  return _then(_AppUser(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,currentCefrLevel: null == currentCefrLevel ? _self.currentCefrLevel : currentCefrLevel // ignore: cast_nullable_to_non_nullable
as String,currentXP: null == currentXP ? _self.currentXP : currentXP // ignore: cast_nullable_to_non_nullable
as int,groqKeyConfigured: null == groqKeyConfigured ? _self.groqKeyConfigured : groqKeyConfigured // ignore: cast_nullable_to_non_nullable
as bool,geminiKeyConfigured: null == geminiKeyConfigured ? _self.geminiKeyConfigured : geminiKeyConfigured // ignore: cast_nullable_to_non_nullable
as bool,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,totalSessionCount: null == totalSessionCount ? _self.totalSessionCount : totalSessionCount // ignore: cast_nullable_to_non_nullable
as int,totalSpeakingSeconds: null == totalSpeakingSeconds ? _self.totalSpeakingSeconds : totalSpeakingSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
