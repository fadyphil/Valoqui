// lib/core/data/repositories/android_stt_repository.dart

import "package:fpdart/fpdart.dart";
import "package:valoqui/core/data/datasources/android_stt_datasource.dart";
import "package:valoqui/core/domain/models/app_failure.dart";
import "package:valoqui/core/domain/repositories/stt_repository.dart";

@Deprecated(
  'Migrating to offline Sherpa-ONNX unified pipeline to fix Android OS cutoffs. '
  'Use SherpaSttRepository instead. (ARCH-101)',
)
class AndroidSttRepository implements SttRepository {
  final AndroidSttDatasource _datasource;

  const AndroidSttRepository({required AndroidSttDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<AppFailure, void>> initialize() async {
    final result = await _datasource.initialize();
    return result.map((_) {});
  }

  @override
  Stream<String> get transcriptStream => _datasource.transcriptStream;

  @override
  void startListening() {
    _datasource.startListening(alwaysOnMode: true);
  }

  @override
  void stopListening() {
    _datasource.stopListening();
  }

  @override
  Future<void> dispose() => _datasource.dispose();
}
