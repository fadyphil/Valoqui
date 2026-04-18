// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConversationMessage {

/// "user" or "assistant" — matches the role strings expected by the
/// Groq / Gemini chat API.
 String get role; String get content; DateTime get timestamp;
/// Create a copy of ConversationMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationMessageCopyWith<ConversationMessage> get copyWith => _$ConversationMessageCopyWithImpl<ConversationMessage>(this as ConversationMessage, _$identity);

  /// Serializes this ConversationMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationMessage&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,content,timestamp);

@override
String toString() {
  return 'ConversationMessage(role: $role, content: $content, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $ConversationMessageCopyWith<$Res>  {
  factory $ConversationMessageCopyWith(ConversationMessage value, $Res Function(ConversationMessage) _then) = _$ConversationMessageCopyWithImpl;
@useResult
$Res call({
 String role, String content, DateTime timestamp
});




}
/// @nodoc
class _$ConversationMessageCopyWithImpl<$Res>
    implements $ConversationMessageCopyWith<$Res> {
  _$ConversationMessageCopyWithImpl(this._self, this._then);

  final ConversationMessage _self;
  final $Res Function(ConversationMessage) _then;

/// Create a copy of ConversationMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? content = null,Object? timestamp = null,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationMessage].
extension ConversationMessagePatterns on ConversationMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationMessage value)  $default,){
final _that = this;
switch (_that) {
case _ConversationMessage():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role,  String content,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationMessage() when $default != null:
return $default(_that.role,_that.content,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role,  String content,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _ConversationMessage():
return $default(_that.role,_that.content,_that.timestamp);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role,  String content,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _ConversationMessage() when $default != null:
return $default(_that.role,_that.content,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationMessage implements ConversationMessage {
  const _ConversationMessage({required this.role, required this.content, required this.timestamp});
  factory _ConversationMessage.fromJson(Map<String, dynamic> json) => _$ConversationMessageFromJson(json);

/// "user" or "assistant" — matches the role strings expected by the
/// Groq / Gemini chat API.
@override final  String role;
@override final  String content;
@override final  DateTime timestamp;

/// Create a copy of ConversationMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationMessageCopyWith<_ConversationMessage> get copyWith => __$ConversationMessageCopyWithImpl<_ConversationMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationMessage&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,content,timestamp);

@override
String toString() {
  return 'ConversationMessage(role: $role, content: $content, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$ConversationMessageCopyWith<$Res> implements $ConversationMessageCopyWith<$Res> {
  factory _$ConversationMessageCopyWith(_ConversationMessage value, $Res Function(_ConversationMessage) _then) = __$ConversationMessageCopyWithImpl;
@override @useResult
$Res call({
 String role, String content, DateTime timestamp
});




}
/// @nodoc
class __$ConversationMessageCopyWithImpl<$Res>
    implements _$ConversationMessageCopyWith<$Res> {
  __$ConversationMessageCopyWithImpl(this._self, this._then);

  final _ConversationMessage _self;
  final $Res Function(_ConversationMessage) _then;

/// Create a copy of ConversationMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? content = null,Object? timestamp = null,}) {
  return _then(_ConversationMessage(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
