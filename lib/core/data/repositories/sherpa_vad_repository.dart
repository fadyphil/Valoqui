// lib/core/data/repositories/sherpa_vad_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/sherpa_vad_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/vad_repository.dart";

class SherpaVadRepository implements VadRepository {
  final SherpaVadDatasource _datasource;

  const SherpaVadRepository({required SherpaVadDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Either<AppFailure, void>> initialize() =>
      _datasource.initialize();

  @override
  Future<Either<AppFailure, void>> startMonitoring() =>
      _datasource.startMonitoring();

  @override
  Future<void> stopMonitoring() => _datasource.stopMonitoring();

  @override
  Stream<bool> get voiceActivityStream => _datasource.voiceActivityStream;

  @override
  Future<void> dispose() => _datasource.dispose();
}
