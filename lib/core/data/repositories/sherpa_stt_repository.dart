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
  Future<Either<AppFailure, bool>> initialize() async {
    final result = await _datasource.initialize();
    return result.map((_) => true); // Maps void to bool to satisfy interface
  }

  @override
  Stream<String> get transcriptStream => _datasource.textStream;

  @override
  Stream<double> get amplitudeStream => _datasource.amplitudeStream;

  @override
  bool get isListening => _datasource.isListening;

  @override
  Future<Either<AppFailure, void>> startListening() async {
    _datasource.startListening();
    return right(null);
  }

  @override
  Future<Either<AppFailure, String>> stopListening() async {
    final resultText = await _datasource.stopListening();
    return right(resultText);
  }

  @override
  Future<void> dispose() => _datasource.dispose();
}
