// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationMessage _$ConversationMessageFromJson(Map<String, dynamic> json) =>
    _ConversationMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ConversationMessageToJson(
  _ConversationMessage instance,
) => <String, dynamic>{
  'role': instance.role,
  'content': instance.content,
  'timestamp': instance.timestamp.toIso8601String(),
};
