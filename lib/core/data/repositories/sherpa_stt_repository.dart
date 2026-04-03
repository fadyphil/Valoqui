// lib/core/data/repositories/sherpa_stt_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/sherpa_stt_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/stt_repository.dart";

class SherpaSttRepository implements SttRepository {
  final SherpaSttDatasource _datasource;

  const SherpaSttRepository({required SherpaSttDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<AppFailure, void>> initialize() => _datasource.initialize();

  @override
  Stream<String> get transcriptStream => _datasource.textStream;

  @override
  void startListening() => _datasource.startListening();

  @override
  void stopListening() => _datasource.stopListening();

  @override
  Future<void> dispose() => _datasource.dispose();
}
