// lib/core/data/repositories/android_stt_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/android_stt_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/stt_repository.dart";

class AndroidSttRepository implements SttRepository {
  final AndroidSttDatasource _datasource;

  const AndroidSttRepository({required AndroidSttDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<AppFailure, bool>> initialize() => _datasource.initialize();

  @override
  Stream<String> get transcriptStream => _datasource.transcriptStream;

  @override
  Stream<String> get finalTranscriptStream => _datasource.finalTranscriptStream;

  @override
  Future<Either<AppFailure, void>> startListening() =>
      _datasource.startListening();

  @override
  Future<Either<AppFailure, String>> stopListening() =>
      _datasource.stopListening();

  @override
  bool get isListening => _datasource.isListening;

  @override
  Future<void> dispose() => _datasource.dispose();
}
