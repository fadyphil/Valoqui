// lib/core/data/repositories/sherpa_tts_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/sherpa_tts_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/tts_repository.dart";

class SherpaTtsRepository implements TtsRepository {
  final SherpaTtsDatasource _datasource;

  const SherpaTtsRepository({required SherpaTtsDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<AppFailure, void>> initialize() => _datasource.initialize();

  @override
  Future<void> warmUp() => _datasource.warmUp();

  @override
  Future<Either<AppFailure, void>> speak(String text) =>
      _datasource.speak(text);

  @override
  Future<void> stop() => _datasource.stop();

  @override
  bool get isSpeaking => _datasource.isSpeaking;

  @override
  Stream<bool> get speakingStateStream => _datasource.speakingStateStream;

  @override
  Future<void> dispose() => _datasource.dispose();
}
