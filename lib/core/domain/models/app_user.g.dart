// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  displayName: json['displayName'] as String,
  email: json['email'] as String,
  currentCefrLevel: json['currentCefrLevel'] as String? ?? "A1",
  currentXP: (json['currentXP'] as num?)?.toInt() ?? 0,
  groqKeyConfigured: json['groqKeyConfigured'] as bool? ?? false,
  geminiKeyConfigured: json['geminiKeyConfigured'] as bool? ?? false,
  streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
  totalSessionCount: (json['totalSessionCount'] as num?)?.toInt() ?? 0,
  totalSpeakingSeconds: (json['totalSpeakingSeconds'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'displayName': instance.displayName,
  'email': instance.email,
  'currentCefrLevel': instance.currentCefrLevel,
  'currentXP': instance.currentXP,
  'groqKeyConfigured': instance.groqKeyConfigured,
  'geminiKeyConfigured': instance.geminiKeyConfigured,
  'streakDays': instance.streakDays,
  'totalSessionCount': instance.totalSessionCount,
  'totalSpeakingSeconds': instance.totalSpeakingSeconds,
};
