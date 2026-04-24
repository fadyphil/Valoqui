// lib/core/data/repositories/sherpa_vad_repository.dart

import "dart:typed_data";

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/sherpa_vad_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/vad_repository.dart";

class SherpaVadRepository implements VadRepository {
  final SherpaVadDatasource _datasource;

  const SherpaVadRepository({required SherpaVadDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<AppFailure, void>> initialize() => _datasource.initialize();

  @override
  Future<Either<AppFailure, void>> startMonitoring({bool enableVad = true}) =>
      _datasource.startMonitoring(enableVad: enableVad);

  @override
  Future<void> stopMonitoring() => _datasource.stopMonitoring();

  @override
  Stream<bool> get voiceActivityStream => _datasource.voiceActivityStream;

  @override
  Stream<Float32List> get speechSegmentStream =>
      _datasource.speechSegmentStream;

  @override
  Stream<Uint8List> get audioStream => _datasource.audioStream;

  @override
  Future<void> dispose() => _datasource.dispose();
}
