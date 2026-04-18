// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionReport {

@JsonKey(name: "overall_grade") String get overallGrade;@JsonKey(name: "fluency_score") int get fluencyScore;@JsonKey(name: "grammar_score") int get grammarScore;@JsonKey(name: "vocabulary_score") int get vocabularyScore;@JsonKey(name: "session_duration_seconds") int get sessionDurationSeconds;@JsonKey(name: "active_speaking_seconds") int get activeSpeakingSeconds;@JsonKey(name: "spanish_word_count") int get spanishWordCount;@JsonKey(name: "topics_covered") List<String> get topicsCovered; List<MistakeItem> get mistakes;@JsonKey(name: "vocabulary_highlights") List<VocabularyHighlight> get vocabularyHighlights;@JsonKey(name: "fluency_note") String get fluencyNote;@JsonKey(name: "grammar_note") String get grammarNote;@JsonKey(name: "vocabulary_note") String get vocabularyNote; String get encouragement;@JsonKey(name: "xp_breakdown") XpBreakdown get xpBreakdown;
/// Create a copy of SessionReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionReportCopyWith<SessionReport> get copyWith => _$SessionReportCopyWithImpl<SessionReport>(this as SessionReport, _$identity);

  /// Serializes this SessionReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionReport&&(identical(other.overallGrade, overallGrade) || other.overallGrade == overallGrade)&&(identical(other.fluencyScore, fluencyScore) || other.fluencyScore == fluencyScore)&&(identical(other.grammarScore, grammarScore) || other.grammarScore == grammarScore)&&(identical(other.vocabularyScore, vocabularyScore) || other.vocabularyScore == vocabularyScore)&&(identical(other.sessionDurationSeconds, sessionDurationSeconds) || other.sessionDurationSeconds == sessionDurationSeconds)&&(identical(other.activeSpeakingSeconds, activeSpeakingSeconds) || other.activeSpeakingSeconds == activeSpeakingSeconds)&&(identical(other.spanishWordCount, spanishWordCount) || other.spanishWordCount == spanishWordCount)&&const DeepCollectionEquality().equals(other.topicsCovered, topicsCovered)&&const DeepCollectionEquality().equals(other.mistakes, mistakes)&&const DeepCollectionEquality().equals(other.vocabularyHighlights, vocabularyHighlights)&&(identical(other.fluencyNote, fluencyNote) || other.fluencyNote == fluencyNote)&&(identical(other.grammarNote, grammarNote) || other.grammarNote == grammarNote)&&(identical(other.vocabularyNote, vocabularyNote) || other.vocabularyNote == vocabularyNote)&&(identical(other.encouragement, encouragement) || other.encouragement == encouragement)&&(identical(other.xpBreakdown, xpBreakdown) || other.xpBreakdown == xpBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallGrade,fluencyScore,grammarScore,vocabularyScore,sessionDurationSeconds,activeSpeakingSeconds,spanishWordCount,const DeepCollectionEquality().hash(topicsCovered),const DeepCollectionEquality().hash(mistakes),const DeepCollectionEquality().hash(vocabularyHighlights),fluencyNote,grammarNote,vocabularyNote,encouragement,xpBreakdown);

@override
String toString() {
  return 'SessionReport(overallGrade: $overallGrade, fluencyScore: $fluencyScore, grammarScore: $grammarScore, vocabularyScore: $vocabularyScore, sessionDurationSeconds: $sessionDurationSeconds, activeSpeakingSeconds: $activeSpeakingSeconds, spanishWordCount: $spanishWordCount, topicsCovered: $topicsCovered, mistakes: $mistakes, vocabularyHighlights: $vocabularyHighlights, fluencyNote: $fluencyNote, grammarNote: $grammarNote, vocabularyNote: $vocabularyNote, encouragement: $encouragement, xpBreakdown: $xpBreakdown)';
}


}

/// @nodoc
abstract mixin class $SessionReportCopyWith<$Res>  {
  factory $SessionReportCopyWith(SessionReport value, $Res Function(SessionReport) _then) = _$SessionReportCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "overall_grade") String overallGrade,@JsonKey(name: "fluency_score") int fluencyScore,@JsonKey(name: "grammar_score") int grammarScore,@JsonKey(name: "vocabulary_score") int vocabularyScore,@JsonKey(name: "session_duration_seconds") int sessionDurationSeconds,@JsonKey(name: "active_speaking_seconds") int activeSpeakingSeconds,@JsonKey(name: "spanish_word_count") int spanishWordCount,@JsonKey(name: "topics_covered") List<String> topicsCovered, List<MistakeItem> mistakes,@JsonKey(name: "vocabulary_highlights") List<VocabularyHighlight> vocabularyHighlights,@JsonKey(name: "fluency_note") String fluencyNote,@JsonKey(name: "grammar_note") String grammarNote,@JsonKey(name: "vocabulary_note") String vocabularyNote, String encouragement,@JsonKey(name: "xp_breakdown") XpBreakdown xpBreakdown
});


$XpBreakdownCopyWith<$Res> get xpBreakdown;

}
/// @nodoc
class _$SessionReportCopyWithImpl<$Res>
    implements $SessionReportCopyWith<$Res> {
  _$SessionReportCopyWithImpl(this._self, this._then);

  final SessionReport _self;
  final $Res Function(SessionReport) _then;

/// Create a copy of SessionReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallGrade = null,Object? fluencyScore = null,Object? grammarScore = null,Object? vocabularyScore = null,Object? sessionDurationSeconds = null,Object? activeSpeakingSeconds = null,Object? spanishWordCount = null,Object? topicsCovered = null,Object? mistakes = null,Object? vocabularyHighlights = null,Object? fluencyNote = null,Object? grammarNote = null,Object? vocabularyNote = null,Object? encouragement = null,Object? xpBreakdown = null,}) {
  return _then(_self.copyWith(
overallGrade: null == overallGrade ? _self.overallGrade : overallGrade // ignore: cast_nullable_to_non_nullable
as String,fluencyScore: null == fluencyScore ? _self.fluencyScore : fluencyScore // ignore: cast_nullable_to_non_nullable
as int,grammarScore: null == grammarScore ? _self.grammarScore : grammarScore // ignore: cast_nullable_to_non_nullable
as int,vocabularyScore: null == vocabularyScore ? _self.vocabularyScore : vocabularyScore // ignore: cast_nullable_to_non_nullable
as int,sessionDurationSeconds: null == sessionDurationSeconds ? _self.sessionDurationSeconds : sessionDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,activeSpeakingSeconds: null == activeSpeakingSeconds ? _self.activeSpeakingSeconds : activeSpeakingSeconds // ignore: cast_nullable_to_non_nullable
as int,spanishWordCount: null == spanishWordCount ? _self.spanishWordCount : spanishWordCount // ignore: cast_nullable_to_non_nullable
as int,topicsCovered: null == topicsCovered ? _self.topicsCovered : topicsCovered // ignore: cast_nullable_to_non_nullable
as List<String>,mistakes: null == mistakes ? _self.mistakes : mistakes // ignore: cast_nullable_to_non_nullable
as List<MistakeItem>,vocabularyHighlights: null == vocabularyHighlights ? _self.vocabularyHighlights : vocabularyHighlights // ignore: cast_nullable_to_non_nullable
as List<VocabularyHighlight>,fluencyNote: null == fluencyNote ? _self.fluencyNote : fluencyNote // ignore: cast_nullable_to_non_nullable
as String,grammarNote: null == grammarNote ? _self.grammarNote : grammarNote // ignore: cast_nullable_to_non_nullable
as String,vocabularyNote: null == vocabularyNote ? _self.vocabularyNote : vocabularyNote // ignore: cast_nullable_to_non_nullable
as String,encouragement: null == encouragement ? _self.encouragement : encouragement // ignore: cast_nullable_to_non_nullable
as String,xpBreakdown: null == xpBreakdown ? _self.xpBreakdown : xpBreakdown // ignore: cast_nullable_to_non_nullable
as XpBreakdown,
  ));
}
/// Create a copy of SessionReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XpBreakdownCopyWith<$Res> get xpBreakdown {
  
  return $XpBreakdownCopyWith<$Res>(_self.xpBreakdown, (value) {
    return _then(_self.copyWith(xpBreakdown: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionReport].
extension SessionReportPatterns on SessionReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionReport value)  $default,){
final _that = this;
switch (_that) {
case _SessionReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionReport value)?  $default,){
final _that = this;
switch (_that) {
case _SessionReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "overall_grade")  String overallGrade, @JsonKey(name: "fluency_score")  int fluencyScore, @JsonKey(name: "grammar_score")  int grammarScore, @JsonKey(name: "vocabulary_score")  int vocabularyScore, @JsonKey(name: "session_duration_seconds")  int sessionDurationSeconds, @JsonKey(name: "active_speaking_seconds")  int activeSpeakingSeconds, @JsonKey(name: "spanish_word_count")  int spanishWordCount, @JsonKey(name: "topics_covered")  List<String> topicsCovered,  List<MistakeItem> mistakes, @JsonKey(name: "vocabulary_highlights")  List<VocabularyHighlight> vocabularyHighlights, @JsonKey(name: "fluency_note")  String fluencyNote, @JsonKey(name: "grammar_note")  String grammarNote, @JsonKey(name: "vocabulary_note")  String vocabularyNote,  String encouragement, @JsonKey(name: "xp_breakdown")  XpBreakdown xpBreakdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionReport() when $default != null:
return $default(_that.overallGrade,_that.fluencyScore,_that.grammarScore,_that.vocabularyScore,_that.sessionDurationSeconds,_that.activeSpeakingSeconds,_that.spanishWordCount,_that.topicsCovered,_that.mistakes,_that.vocabularyHighlights,_that.fluencyNote,_that.grammarNote,_that.vocabularyNote,_that.encouragement,_that.xpBreakdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "overall_grade")  String overallGrade, @JsonKey(name: "fluency_score")  int fluencyScore, @JsonKey(name: "grammar_score")  int grammarScore, @JsonKey(name: "vocabulary_score")  int vocabularyScore, @JsonKey(name: "session_duration_seconds")  int sessionDurationSeconds, @JsonKey(name: "active_speaking_seconds")  int activeSpeakingSeconds, @JsonKey(name: "spanish_word_count")  int spanishWordCount, @JsonKey(name: "topics_covered")  List<String> topicsCovered,  List<MistakeItem> mistakes, @JsonKey(name: "vocabulary_highlights")  List<VocabularyHighlight> vocabularyHighlights, @JsonKey(name: "fluency_note")  String fluencyNote, @JsonKey(name: "grammar_note")  String grammarNote, @JsonKey(name: "vocabulary_note")  String vocabularyNote,  String encouragement, @JsonKey(name: "xp_breakdown")  XpBreakdown xpBreakdown)  $default,) {final _that = this;
switch (_that) {
case _SessionReport():
return $default(_that.overallGrade,_that.fluencyScore,_that.grammarScore,_that.vocabularyScore,_that.sessionDurationSeconds,_that.activeSpeakingSeconds,_that.spanishWordCount,_that.topicsCovered,_that.mistakes,_that.vocabularyHighlights,_that.fluencyNote,_that.grammarNote,_that.vocabularyNote,_that.encouragement,_that.xpBreakdown);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "overall_grade")  String overallGrade, @JsonKey(name: "fluency_score")  int fluencyScore, @JsonKey(name: "grammar_score")  int grammarScore, @JsonKey(name: "vocabulary_score")  int vocabularyScore, @JsonKey(name: "session_duration_seconds")  int sessionDurationSeconds, @JsonKey(name: "active_speaking_seconds")  int activeSpeakingSeconds, @JsonKey(name: "spanish_word_count")  int spanishWordCount, @JsonKey(name: "topics_covered")  List<String> topicsCovered,  List<MistakeItem> mistakes, @JsonKey(name: "vocabulary_highlights")  List<VocabularyHighlight> vocabularyHighlights, @JsonKey(name: "fluency_note")  String fluencyNote, @JsonKey(name: "grammar_note")  String grammarNote, @JsonKey(name: "vocabulary_note")  String vocabularyNote,  String encouragement, @JsonKey(name: "xp_breakdown")  XpBreakdown xpBreakdown)?  $default,) {final _that = this;
switch (_that) {
case _SessionReport() when $default != null:
return $default(_that.overallGrade,_that.fluencyScore,_that.grammarScore,_that.vocabularyScore,_that.sessionDurationSeconds,_that.activeSpeakingSeconds,_that.spanishWordCount,_that.topicsCovered,_that.mistakes,_that.vocabularyHighlights,_that.fluencyNote,_that.grammarNote,_that.vocabularyNote,_that.encouragement,_that.xpBreakdown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionReport implements SessionReport {
  const _SessionReport({@JsonKey(name: "overall_grade") required this.overallGrade, @JsonKey(name: "fluency_score") required this.fluencyScore, @JsonKey(name: "grammar_score") required this.grammarScore, @JsonKey(name: "vocabulary_score") required this.vocabularyScore, @JsonKey(name: "session_duration_seconds") required this.sessionDurationSeconds, @JsonKey(name: "active_speaking_seconds") required this.activeSpeakingSeconds, @JsonKey(name: "spanish_word_count") required this.spanishWordCount, @JsonKey(name: "topics_covered") required final  List<String> topicsCovered, required final  List<MistakeItem> mistakes, @JsonKey(name: "vocabulary_highlights") required final  List<VocabularyHighlight> vocabularyHighlights, @JsonKey(name: "fluency_note") required this.fluencyNote, @JsonKey(name: "grammar_note") required this.grammarNote, @JsonKey(name: "vocabulary_note") required this.vocabularyNote, required this.encouragement, @JsonKey(name: "xp_breakdown") required this.xpBreakdown}): _topicsCovered = topicsCovered,_mistakes = mistakes,_vocabularyHighlights = vocabularyHighlights;
  factory _SessionReport.fromJson(Map<String, dynamic> json) => _$SessionReportFromJson(json);

@override@JsonKey(name: "overall_grade") final  String overallGrade;
@override@JsonKey(name: "fluency_score") final  int fluencyScore;
@override@JsonKey(name: "grammar_score") final  int grammarScore;
@override@JsonKey(name: "vocabulary_score") final  int vocabularyScore;
@override@JsonKey(name: "session_duration_seconds") final  int sessionDurationSeconds;
@override@JsonKey(name: "active_speaking_seconds") final  int activeSpeakingSeconds;
@override@JsonKey(name: "spanish_word_count") final  int spanishWordCount;
 final  List<String> _topicsCovered;
@override@JsonKey(name: "topics_covered") List<String> get topicsCovered {
  if (_topicsCovered is EqualUnmodifiableListView) return _topicsCovered;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topicsCovered);
}

 final  List<MistakeItem> _mistakes;
@override List<MistakeItem> get mistakes {
  if (_mistakes is EqualUnmodifiableListView) return _mistakes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mistakes);
}

 final  List<VocabularyHighlight> _vocabularyHighlights;
@override@JsonKey(name: "vocabulary_highlights") List<VocabularyHighlight> get vocabularyHighlights {
  if (_vocabularyHighlights is EqualUnmodifiableListView) return _vocabularyHighlights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vocabularyHighlights);
}

@override@JsonKey(name: "fluency_note") final  String fluencyNote;
@override@JsonKey(name: "grammar_note") final  String grammarNote;
@override@JsonKey(name: "vocabulary_note") final  String vocabularyNote;
@override final  String encouragement;
@override@JsonKey(name: "xp_breakdown") final  XpBreakdown xpBreakdown;

/// Create a copy of SessionReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionReportCopyWith<_SessionReport> get copyWith => __$SessionReportCopyWithImpl<_SessionReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionReport&&(identical(other.overallGrade, overallGrade) || other.overallGrade == overallGrade)&&(identical(other.fluencyScore, fluencyScore) || other.fluencyScore == fluencyScore)&&(identical(other.grammarScore, grammarScore) || other.grammarScore == grammarScore)&&(identical(other.vocabularyScore, vocabularyScore) || other.vocabularyScore == vocabularyScore)&&(identical(other.sessionDurationSeconds, sessionDurationSeconds) || other.sessionDurationSeconds == sessionDurationSeconds)&&(identical(other.activeSpeakingSeconds, activeSpeakingSeconds) || other.activeSpeakingSeconds == activeSpeakingSeconds)&&(identical(other.spanishWordCount, spanishWordCount) || other.spanishWordCount == spanishWordCount)&&const DeepCollectionEquality().equals(other._topicsCovered, _topicsCovered)&&const DeepCollectionEquality().equals(other._mistakes, _mistakes)&&const DeepCollectionEquality().equals(other._vocabularyHighlights, _vocabularyHighlights)&&(identical(other.fluencyNote, fluencyNote) || other.fluencyNote == fluencyNote)&&(identical(other.grammarNote, grammarNote) || other.grammarNote == grammarNote)&&(identical(other.vocabularyNote, vocabularyNote) || other.vocabularyNote == vocabularyNote)&&(identical(other.encouragement, encouragement) || other.encouragement == encouragement)&&(identical(other.xpBreakdown, xpBreakdown) || other.xpBreakdown == xpBreakdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallGrade,fluencyScore,grammarScore,vocabularyScore,sessionDurationSeconds,activeSpeakingSeconds,spanishWordCount,const DeepCollectionEquality().hash(_topicsCovered),const DeepCollectionEquality().hash(_mistakes),const DeepCollectionEquality().hash(_vocabularyHighlights),fluencyNote,grammarNote,vocabularyNote,encouragement,xpBreakdown);

@override
String toString() {
  return 'SessionReport(overallGrade: $overallGrade, fluencyScore: $fluencyScore, grammarScore: $grammarScore, vocabularyScore: $vocabularyScore, sessionDurationSeconds: $sessionDurationSeconds, activeSpeakingSeconds: $activeSpeakingSeconds, spanishWordCount: $spanishWordCount, topicsCovered: $topicsCovered, mistakes: $mistakes, vocabularyHighlights: $vocabularyHighlights, fluencyNote: $fluencyNote, grammarNote: $grammarNote, vocabularyNote: $vocabularyNote, encouragement: $encouragement, xpBreakdown: $xpBreakdown)';
}


}

/// @nodoc
abstract mixin class _$SessionReportCopyWith<$Res> implements $SessionReportCopyWith<$Res> {
  factory _$SessionReportCopyWith(_SessionReport value, $Res Function(_SessionReport) _then) = __$SessionReportCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "overall_grade") String overallGrade,@JsonKey(name: "fluency_score") int fluencyScore,@JsonKey(name: "grammar_score") int grammarScore,@JsonKey(name: "vocabulary_score") int vocabularyScore,@JsonKey(name: "session_duration_seconds") int sessionDurationSeconds,@JsonKey(name: "active_speaking_seconds") int activeSpeakingSeconds,@JsonKey(name: "spanish_word_count") int spanishWordCount,@JsonKey(name: "topics_covered") List<String> topicsCovered, List<MistakeItem> mistakes,@JsonKey(name: "vocabulary_highlights") List<VocabularyHighlight> vocabularyHighlights,@JsonKey(name: "fluency_note") String fluencyNote,@JsonKey(name: "grammar_note") String grammarNote,@JsonKey(name: "vocabulary_note") String vocabularyNote, String encouragement,@JsonKey(name: "xp_breakdown") XpBreakdown xpBreakdown
});


@override $XpBreakdownCopyWith<$Res> get xpBreakdown;

}
/// @nodoc
class __$SessionReportCopyWithImpl<$Res>
    implements _$SessionReportCopyWith<$Res> {
  __$SessionReportCopyWithImpl(this._self, this._then);

  final _SessionReport _self;
  final $Res Function(_SessionReport) _then;

/// Create a copy of SessionReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallGrade = null,Object? fluencyScore = null,Object? grammarScore = null,Object? vocabularyScore = null,Object? sessionDurationSeconds = null,Object? activeSpeakingSeconds = null,Object? spanishWordCount = null,Object? topicsCovered = null,Object? mistakes = null,Object? vocabularyHighlights = null,Object? fluencyNote = null,Object? grammarNote = null,Object? vocabularyNote = null,Object? encouragement = null,Object? xpBreakdown = null,}) {
  return _then(_SessionReport(
overallGrade: null == overallGrade ? _self.overallGrade : overallGrade // ignore: cast_nullable_to_non_nullable
as String,fluencyScore: null == fluencyScore ? _self.fluencyScore : fluencyScore // ignore: cast_nullable_to_non_nullable
as int,grammarScore: null == grammarScore ? _self.grammarScore : grammarScore // ignore: cast_nullable_to_non_nullable
as int,vocabularyScore: null == vocabularyScore ? _self.vocabularyScore : vocabularyScore // ignore: cast_nullable_to_non_nullable
as int,sessionDurationSeconds: null == sessionDurationSeconds ? _self.sessionDurationSeconds : sessionDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,activeSpeakingSeconds: null == activeSpeakingSeconds ? _self.activeSpeakingSeconds : activeSpeakingSeconds // ignore: cast_nullable_to_non_nullable
as int,spanishWordCount: null == spanishWordCount ? _self.spanishWordCount : spanishWordCount // ignore: cast_nullable_to_non_nullable
as int,topicsCovered: null == topicsCovered ? _self._topicsCovered : topicsCovered // ignore: cast_nullable_to_non_nullable
as List<String>,mistakes: null == mistakes ? _self._mistakes : mistakes // ignore: cast_nullable_to_non_nullable
as List<MistakeItem>,vocabularyHighlights: null == vocabularyHighlights ? _self._vocabularyHighlights : vocabularyHighlights // ignore: cast_nullable_to_non_nullable
as List<VocabularyHighlight>,fluencyNote: null == fluencyNote ? _self.fluencyNote : fluencyNote // ignore: cast_nullable_to_non_nullable
as String,grammarNote: null == grammarNote ? _self.grammarNote : grammarNote // ignore: cast_nullable_to_non_nullable
as String,vocabularyNote: null == vocabularyNote ? _self.vocabularyNote : vocabularyNote // ignore: cast_nullable_to_non_nullable
as String,encouragement: null == encouragement ? _self.encouragement : encouragement // ignore: cast_nullable_to_non_nullable
as String,xpBreakdown: null == xpBreakdown ? _self.xpBreakdown : xpBreakdown // ignore: cast_nullable_to_non_nullable
as XpBreakdown,
  ));
}

/// Create a copy of SessionReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$XpBreakdownCopyWith<$Res> get xpBreakdown {
  
  return $XpBreakdownCopyWith<$Res>(_self.xpBreakdown, (value) {
    return _then(_self.copyWith(xpBreakdown: value));
  });
}
}


/// @nodoc
mixin _$MistakeItem {

@JsonKey(name: "what_user_said") String get whatUserSaid; String get correction; String get explanation; String get category; String get severity;
/// Create a copy of MistakeItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MistakeItemCopyWith<MistakeItem> get copyWith => _$MistakeItemCopyWithImpl<MistakeItem>(this as MistakeItem, _$identity);

  /// Serializes this MistakeItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MistakeItem&&(identical(other.whatUserSaid, whatUserSaid) || other.whatUserSaid == whatUserSaid)&&(identical(other.correction, correction) || other.correction == correction)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.category, category) || other.category == category)&&(identical(other.severity, severity) || other.severity == severity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,whatUserSaid,correction,explanation,category,severity);

@override
String toString() {
  return 'MistakeItem(whatUserSaid: $whatUserSaid, correction: $correction, explanation: $explanation, category: $category, severity: $severity)';
}


}

/// @nodoc
abstract mixin class $MistakeItemCopyWith<$Res>  {
  factory $MistakeItemCopyWith(MistakeItem value, $Res Function(MistakeItem) _then) = _$MistakeItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "what_user_said") String whatUserSaid, String correction, String explanation, String category, String severity
});




}
/// @nodoc
class _$MistakeItemCopyWithImpl<$Res>
    implements $MistakeItemCopyWith<$Res> {
  _$MistakeItemCopyWithImpl(this._self, this._then);

  final MistakeItem _self;
  final $Res Function(MistakeItem) _then;

/// Create a copy of MistakeItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? whatUserSaid = null,Object? correction = null,Object? explanation = null,Object? category = null,Object? severity = null,}) {
  return _then(_self.copyWith(
whatUserSaid: null == whatUserSaid ? _self.whatUserSaid : whatUserSaid // ignore: cast_nullable_to_non_nullable
as String,correction: null == correction ? _self.correction : correction // ignore: cast_nullable_to_non_nullable
as String,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MistakeItem].
extension MistakeItemPatterns on MistakeItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MistakeItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MistakeItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MistakeItem value)  $default,){
final _that = this;
switch (_that) {
case _MistakeItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MistakeItem value)?  $default,){
final _that = this;
switch (_that) {
case _MistakeItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "what_user_said")  String whatUserSaid,  String correction,  String explanation,  String category,  String severity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MistakeItem() when $default != null:
return $default(_that.whatUserSaid,_that.correction,_that.explanation,_that.category,_that.severity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "what_user_said")  String whatUserSaid,  String correction,  String explanation,  String category,  String severity)  $default,) {final _that = this;
switch (_that) {
case _MistakeItem():
return $default(_that.whatUserSaid,_that.correction,_that.explanation,_that.category,_that.severity);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "what_user_said")  String whatUserSaid,  String correction,  String explanation,  String category,  String severity)?  $default,) {final _that = this;
switch (_that) {
case _MistakeItem() when $default != null:
return $default(_that.whatUserSaid,_that.correction,_that.explanation,_that.category,_that.severity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MistakeItem implements MistakeItem {
  const _MistakeItem({@JsonKey(name: "what_user_said") required this.whatUserSaid, required this.correction, required this.explanation, required this.category, required this.severity});
  factory _MistakeItem.fromJson(Map<String, dynamic> json) => _$MistakeItemFromJson(json);

@override@JsonKey(name: "what_user_said") final  String whatUserSaid;
@override final  String correction;
@override final  String explanation;
@override final  String category;
@override final  String severity;

/// Create a copy of MistakeItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MistakeItemCopyWith<_MistakeItem> get copyWith => __$MistakeItemCopyWithImpl<_MistakeItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MistakeItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MistakeItem&&(identical(other.whatUserSaid, whatUserSaid) || other.whatUserSaid == whatUserSaid)&&(identical(other.correction, correction) || other.correction == correction)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.category, category) || other.category == category)&&(identical(other.severity, severity) || other.severity == severity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,whatUserSaid,correction,explanation,category,severity);

@override
String toString() {
  return 'MistakeItem(whatUserSaid: $whatUserSaid, correction: $correction, explanation: $explanation, category: $category, severity: $severity)';
}


}

/// @nodoc
abstract mixin class _$MistakeItemCopyWith<$Res> implements $MistakeItemCopyWith<$Res> {
  factory _$MistakeItemCopyWith(_MistakeItem value, $Res Function(_MistakeItem) _then) = __$MistakeItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "what_user_said") String whatUserSaid, String correction, String explanation, String category, String severity
});




}
/// @nodoc
class __$MistakeItemCopyWithImpl<$Res>
    implements _$MistakeItemCopyWith<$Res> {
  __$MistakeItemCopyWithImpl(this._self, this._then);

  final _MistakeItem _self;
  final $Res Function(_MistakeItem) _then;

/// Create a copy of MistakeItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? whatUserSaid = null,Object? correction = null,Object? explanation = null,Object? category = null,Object? severity = null,}) {
  return _then(_MistakeItem(
whatUserSaid: null == whatUserSaid ? _self.whatUserSaid : whatUserSaid // ignore: cast_nullable_to_non_nullable
as String,correction: null == correction ? _self.correction : correction // ignore: cast_nullable_to_non_nullable
as String,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VocabularyHighlight {

 String get word; String get english; String get context;@JsonKey(name: "used_correctly") bool get usedCorrectly;
/// Create a copy of VocabularyHighlight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VocabularyHighlightCopyWith<VocabularyHighlight> get copyWith => _$VocabularyHighlightCopyWithImpl<VocabularyHighlight>(this as VocabularyHighlight, _$identity);

  /// Serializes this VocabularyHighlight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VocabularyHighlight&&(identical(other.word, word) || other.word == word)&&(identical(other.english, english) || other.english == english)&&(identical(other.context, context) || other.context == context)&&(identical(other.usedCorrectly, usedCorrectly) || other.usedCorrectly == usedCorrectly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,english,context,usedCorrectly);

@override
String toString() {
  return 'VocabularyHighlight(word: $word, english: $english, context: $context, usedCorrectly: $usedCorrectly)';
}


}

/// @nodoc
abstract mixin class $VocabularyHighlightCopyWith<$Res>  {
  factory $VocabularyHighlightCopyWith(VocabularyHighlight value, $Res Function(VocabularyHighlight) _then) = _$VocabularyHighlightCopyWithImpl;
@useResult
$Res call({
 String word, String english, String context,@JsonKey(name: "used_correctly") bool usedCorrectly
});




}
/// @nodoc
class _$VocabularyHighlightCopyWithImpl<$Res>
    implements $VocabularyHighlightCopyWith<$Res> {
  _$VocabularyHighlightCopyWithImpl(this._self, this._then);

  final VocabularyHighlight _self;
  final $Res Function(VocabularyHighlight) _then;

/// Create a copy of VocabularyHighlight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? word = null,Object? english = null,Object? context = null,Object? usedCorrectly = null,}) {
  return _then(_self.copyWith(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,english: null == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,usedCorrectly: null == usedCorrectly ? _self.usedCorrectly : usedCorrectly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [VocabularyHighlight].
extension VocabularyHighlightPatterns on VocabularyHighlight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VocabularyHighlight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VocabularyHighlight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VocabularyHighlight value)  $default,){
final _that = this;
switch (_that) {
case _VocabularyHighlight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VocabularyHighlight value)?  $default,){
final _that = this;
switch (_that) {
case _VocabularyHighlight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String word,  String english,  String context, @JsonKey(name: "used_correctly")  bool usedCorrectly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VocabularyHighlight() when $default != null:
return $default(_that.word,_that.english,_that.context,_that.usedCorrectly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String word,  String english,  String context, @JsonKey(name: "used_correctly")  bool usedCorrectly)  $default,) {final _that = this;
switch (_that) {
case _VocabularyHighlight():
return $default(_that.word,_that.english,_that.context,_that.usedCorrectly);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String word,  String english,  String context, @JsonKey(name: "used_correctly")  bool usedCorrectly)?  $default,) {final _that = this;
switch (_that) {
case _VocabularyHighlight() when $default != null:
return $default(_that.word,_that.english,_that.context,_that.usedCorrectly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VocabularyHighlight implements VocabularyHighlight {
  const _VocabularyHighlight({required this.word, required this.english, required this.context, @JsonKey(name: "used_correctly") required this.usedCorrectly});
  factory _VocabularyHighlight.fromJson(Map<String, dynamic> json) => _$VocabularyHighlightFromJson(json);

@override final  String word;
@override final  String english;
@override final  String context;
@override@JsonKey(name: "used_correctly") final  bool usedCorrectly;

/// Create a copy of VocabularyHighlight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VocabularyHighlightCopyWith<_VocabularyHighlight> get copyWith => __$VocabularyHighlightCopyWithImpl<_VocabularyHighlight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VocabularyHighlightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VocabularyHighlight&&(identical(other.word, word) || other.word == word)&&(identical(other.english, english) || other.english == english)&&(identical(other.context, context) || other.context == context)&&(identical(other.usedCorrectly, usedCorrectly) || other.usedCorrectly == usedCorrectly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,word,english,context,usedCorrectly);

@override
String toString() {
  return 'VocabularyHighlight(word: $word, english: $english, context: $context, usedCorrectly: $usedCorrectly)';
}


}

/// @nodoc
abstract mixin class _$VocabularyHighlightCopyWith<$Res> implements $VocabularyHighlightCopyWith<$Res> {
  factory _$VocabularyHighlightCopyWith(_VocabularyHighlight value, $Res Function(_VocabularyHighlight) _then) = __$VocabularyHighlightCopyWithImpl;
@override @useResult
$Res call({
 String word, String english, String context,@JsonKey(name: "used_correctly") bool usedCorrectly
});




}
/// @nodoc
class __$VocabularyHighlightCopyWithImpl<$Res>
    implements _$VocabularyHighlightCopyWith<$Res> {
  __$VocabularyHighlightCopyWithImpl(this._self, this._then);

  final _VocabularyHighlight _self;
  final $Res Function(_VocabularyHighlight) _then;

/// Create a copy of VocabularyHighlight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? word = null,Object? english = null,Object? context = null,Object? usedCorrectly = null,}) {
  return _then(_VocabularyHighlight(
word: null == word ? _self.word : word // ignore: cast_nullable_to_non_nullable
as String,english: null == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,usedCorrectly: null == usedCorrectly ? _self.usedCorrectly : usedCorrectly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$XpBreakdown {

@JsonKey(name: "time_speaking_xp") int get timeSpeakingXp;@JsonKey(name: "spanish_words_xp") int get spanishWordsXp;@JsonKey(name: "grammar_bonus_xp") int get grammarBonusXp;@JsonKey(name: "vocabulary_bonus_xp") int get vocabularyBonusXp;@JsonKey(name: "session_completion_xp") int get sessionCompletionXp;@JsonKey(name: "first_session_today_xp") int get firstSessionTodayXp;@JsonKey(name: "total_xp") int get totalXp;
/// Create a copy of XpBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XpBreakdownCopyWith<XpBreakdown> get copyWith => _$XpBreakdownCopyWithImpl<XpBreakdown>(this as XpBreakdown, _$identity);

  /// Serializes this XpBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XpBreakdown&&(identical(other.timeSpeakingXp, timeSpeakingXp) || other.timeSpeakingXp == timeSpeakingXp)&&(identical(other.spanishWordsXp, spanishWordsXp) || other.spanishWordsXp == spanishWordsXp)&&(identical(other.grammarBonusXp, grammarBonusXp) || other.grammarBonusXp == grammarBonusXp)&&(identical(other.vocabularyBonusXp, vocabularyBonusXp) || other.vocabularyBonusXp == vocabularyBonusXp)&&(identical(other.sessionCompletionXp, sessionCompletionXp) || other.sessionCompletionXp == sessionCompletionXp)&&(identical(other.firstSessionTodayXp, firstSessionTodayXp) || other.firstSessionTodayXp == firstSessionTodayXp)&&(identical(other.totalXp, totalXp) || other.totalXp == totalXp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timeSpeakingXp,spanishWordsXp,grammarBonusXp,vocabularyBonusXp,sessionCompletionXp,firstSessionTodayXp,totalXp);

@override
String toString() {
  return 'XpBreakdown(timeSpeakingXp: $timeSpeakingXp, spanishWordsXp: $spanishWordsXp, grammarBonusXp: $grammarBonusXp, vocabularyBonusXp: $vocabularyBonusXp, sessionCompletionXp: $sessionCompletionXp, firstSessionTodayXp: $firstSessionTodayXp, totalXp: $totalXp)';
}


}

/// @nodoc
abstract mixin class $XpBreakdownCopyWith<$Res>  {
  factory $XpBreakdownCopyWith(XpBreakdown value, $Res Function(XpBreakdown) _then) = _$XpBreakdownCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "time_speaking_xp") int timeSpeakingXp,@JsonKey(name: "spanish_words_xp") int spanishWordsXp,@JsonKey(name: "grammar_bonus_xp") int grammarBonusXp,@JsonKey(name: "vocabulary_bonus_xp") int vocabularyBonusXp,@JsonKey(name: "session_completion_xp") int sessionCompletionXp,@JsonKey(name: "first_session_today_xp") int firstSessionTodayXp,@JsonKey(name: "total_xp") int totalXp
});




}
/// @nodoc
class _$XpBreakdownCopyWithImpl<$Res>
    implements $XpBreakdownCopyWith<$Res> {
  _$XpBreakdownCopyWithImpl(this._self, this._then);

  final XpBreakdown _self;
  final $Res Function(XpBreakdown) _then;

/// Create a copy of XpBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timeSpeakingXp = null,Object? spanishWordsXp = null,Object? grammarBonusXp = null,Object? vocabularyBonusXp = null,Object? sessionCompletionXp = null,Object? firstSessionTodayXp = null,Object? totalXp = null,}) {
  return _then(_self.copyWith(
timeSpeakingXp: null == timeSpeakingXp ? _self.timeSpeakingXp : timeSpeakingXp // ignore: cast_nullable_to_non_nullable
as int,spanishWordsXp: null == spanishWordsXp ? _self.spanishWordsXp : spanishWordsXp // ignore: cast_nullable_to_non_nullable
as int,grammarBonusXp: null == grammarBonusXp ? _self.grammarBonusXp : grammarBonusXp // ignore: cast_nullable_to_non_nullable
as int,vocabularyBonusXp: null == vocabularyBonusXp ? _self.vocabularyBonusXp : vocabularyBonusXp // ignore: cast_nullable_to_non_nullable
as int,sessionCompletionXp: null == sessionCompletionXp ? _self.sessionCompletionXp : sessionCompletionXp // ignore: cast_nullable_to_non_nullable
as int,firstSessionTodayXp: null == firstSessionTodayXp ? _self.firstSessionTodayXp : firstSessionTodayXp // ignore: cast_nullable_to_non_nullable
as int,totalXp: null == totalXp ? _self.totalXp : totalXp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [XpBreakdown].
extension XpBreakdownPatterns on XpBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XpBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XpBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XpBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _XpBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XpBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _XpBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "time_speaking_xp")  int timeSpeakingXp, @JsonKey(name: "spanish_words_xp")  int spanishWordsXp, @JsonKey(name: "grammar_bonus_xp")  int grammarBonusXp, @JsonKey(name: "vocabulary_bonus_xp")  int vocabularyBonusXp, @JsonKey(name: "session_completion_xp")  int sessionCompletionXp, @JsonKey(name: "first_session_today_xp")  int firstSessionTodayXp, @JsonKey(name: "total_xp")  int totalXp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XpBreakdown() when $default != null:
return $default(_that.timeSpeakingXp,_that.spanishWordsXp,_that.grammarBonusXp,_that.vocabularyBonusXp,_that.sessionCompletionXp,_that.firstSessionTodayXp,_that.totalXp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "time_speaking_xp")  int timeSpeakingXp, @JsonKey(name: "spanish_words_xp")  int spanishWordsXp, @JsonKey(name: "grammar_bonus_xp")  int grammarBonusXp, @JsonKey(name: "vocabulary_bonus_xp")  int vocabularyBonusXp, @JsonKey(name: "session_completion_xp")  int sessionCompletionXp, @JsonKey(name: "first_session_today_xp")  int firstSessionTodayXp, @JsonKey(name: "total_xp")  int totalXp)  $default,) {final _that = this;
switch (_that) {
case _XpBreakdown():
return $default(_that.timeSpeakingXp,_that.spanishWordsXp,_that.grammarBonusXp,_that.vocabularyBonusXp,_that.sessionCompletionXp,_that.firstSessionTodayXp,_that.totalXp);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "time_speaking_xp")  int timeSpeakingXp, @JsonKey(name: "spanish_words_xp")  int spanishWordsXp, @JsonKey(name: "grammar_bonus_xp")  int grammarBonusXp, @JsonKey(name: "vocabulary_bonus_xp")  int vocabularyBonusXp, @JsonKey(name: "session_completion_xp")  int sessionCompletionXp, @JsonKey(name: "first_session_today_xp")  int firstSessionTodayXp, @JsonKey(name: "total_xp")  int totalXp)?  $default,) {final _that = this;
switch (_that) {
case _XpBreakdown() when $default != null:
return $default(_that.timeSpeakingXp,_that.spanishWordsXp,_that.grammarBonusXp,_that.vocabularyBonusXp,_that.sessionCompletionXp,_that.firstSessionTodayXp,_that.totalXp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _XpBreakdown implements XpBreakdown {
  const _XpBreakdown({@JsonKey(name: "time_speaking_xp") required this.timeSpeakingXp, @JsonKey(name: "spanish_words_xp") required this.spanishWordsXp, @JsonKey(name: "grammar_bonus_xp") required this.grammarBonusXp, @JsonKey(name: "vocabulary_bonus_xp") required this.vocabularyBonusXp, @JsonKey(name: "session_completion_xp") required this.sessionCompletionXp, @JsonKey(name: "first_session_today_xp") required this.firstSessionTodayXp, @JsonKey(name: "total_xp") required this.totalXp});
  factory _XpBreakdown.fromJson(Map<String, dynamic> json) => _$XpBreakdownFromJson(json);

@override@JsonKey(name: "time_speaking_xp") final  int timeSpeakingXp;
@override@JsonKey(name: "spanish_words_xp") final  int spanishWordsXp;
@override@JsonKey(name: "grammar_bonus_xp") final  int grammarBonusXp;
@override@JsonKey(name: "vocabulary_bonus_xp") final  int vocabularyBonusXp;
@override@JsonKey(name: "session_completion_xp") final  int sessionCompletionXp;
@override@JsonKey(name: "first_session_today_xp") final  int firstSessionTodayXp;
@override@JsonKey(name: "total_xp") final  int totalXp;

/// Create a copy of XpBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XpBreakdownCopyWith<_XpBreakdown> get copyWith => __$XpBreakdownCopyWithImpl<_XpBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$XpBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _XpBreakdown&&(identical(other.timeSpeakingXp, timeSpeakingXp) || other.timeSpeakingXp == timeSpeakingXp)&&(identical(other.spanishWordsXp, spanishWordsXp) || other.spanishWordsXp == spanishWordsXp)&&(identical(other.grammarBonusXp, grammarBonusXp) || other.grammarBonusXp == grammarBonusXp)&&(identical(other.vocabularyBonusXp, vocabularyBonusXp) || other.vocabularyBonusXp == vocabularyBonusXp)&&(identical(other.sessionCompletionXp, sessionCompletionXp) || other.sessionCompletionXp == sessionCompletionXp)&&(identical(other.firstSessionTodayXp, firstSessionTodayXp) || other.firstSessionTodayXp == firstSessionTodayXp)&&(identical(other.totalXp, totalXp) || other.totalXp == totalXp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timeSpeakingXp,spanishWordsXp,grammarBonusXp,vocabularyBonusXp,sessionCompletionXp,firstSessionTodayXp,totalXp);

@override
String toString() {
  return 'XpBreakdown(timeSpeakingXp: $timeSpeakingXp, spanishWordsXp: $spanishWordsXp, grammarBonusXp: $grammarBonusXp, vocabularyBonusXp: $vocabularyBonusXp, sessionCompletionXp: $sessionCompletionXp, firstSessionTodayXp: $firstSessionTodayXp, totalXp: $totalXp)';
}


}

/// @nodoc
abstract mixin class _$XpBreakdownCopyWith<$Res> implements $XpBreakdownCopyWith<$Res> {
  factory _$XpBreakdownCopyWith(_XpBreakdown value, $Res Function(_XpBreakdown) _then) = __$XpBreakdownCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "time_speaking_xp") int timeSpeakingXp,@JsonKey(name: "spanish_words_xp") int spanishWordsXp,@JsonKey(name: "grammar_bonus_xp") int grammarBonusXp,@JsonKey(name: "vocabulary_bonus_xp") int vocabularyBonusXp,@JsonKey(name: "session_completion_xp") int sessionCompletionXp,@JsonKey(name: "first_session_today_xp") int firstSessionTodayXp,@JsonKey(name: "total_xp") int totalXp
});




}
/// @nodoc
class __$XpBreakdownCopyWithImpl<$Res>
    implements _$XpBreakdownCopyWith<$Res> {
  __$XpBreakdownCopyWithImpl(this._self, this._then);

  final _XpBreakdown _self;
  final $Res Function(_XpBreakdown) _then;

/// Create a copy of XpBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timeSpeakingXp = null,Object? spanishWordsXp = null,Object? grammarBonusXp = null,Object? vocabularyBonusXp = null,Object? sessionCompletionXp = null,Object? firstSessionTodayXp = null,Object? totalXp = null,}) {
  return _then(_XpBreakdown(
timeSpeakingXp: null == timeSpeakingXp ? _self.timeSpeakingXp : timeSpeakingXp // ignore: cast_nullable_to_non_nullable
as int,spanishWordsXp: null == spanishWordsXp ? _self.spanishWordsXp : spanishWordsXp // ignore: cast_nullable_to_non_nullable
as int,grammarBonusXp: null == grammarBonusXp ? _self.grammarBonusXp : grammarBonusXp // ignore: cast_nullable_to_non_nullable
as int,vocabularyBonusXp: null == vocabularyBonusXp ? _self.vocabularyBonusXp : vocabularyBonusXp // ignore: cast_nullable_to_non_nullable
as int,sessionCompletionXp: null == sessionCompletionXp ? _self.sessionCompletionXp : sessionCompletionXp // ignore: cast_nullable_to_non_nullable
as int,firstSessionTodayXp: null == firstSessionTodayXp ? _self.firstSessionTodayXp : firstSessionTodayXp // ignore: cast_nullable_to_non_nullable
as int,totalXp: null == totalXp ? _self.totalXp : totalXp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
