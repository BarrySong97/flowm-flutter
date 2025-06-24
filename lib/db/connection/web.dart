import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'flowm_database',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );

    if (result.missingFeatures.isNotEmpty && kDebugMode) {
      print(
          'Using ${result.chosenImplementation} due to missing browser features: ${result.missingFeatures}');
    }

    return result.resolvedExecutor;
  }));
}
