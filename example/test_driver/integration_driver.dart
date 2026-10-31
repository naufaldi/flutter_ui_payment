import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves screenshots to $SCREENSHOT_DIR (default build/screenshots) and
/// performance summaries reported by the test to build/perf.
Future<void> main() {
  final dir = Platform.environment['SCREENSHOT_DIR'] ?? 'build/screenshots';
  return integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('$dir/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      // Screenshot runs also report image bytes. They must not overwrite the
      // measurements from the last profile run.
      if (data == null || !data.containsKey('checkout')) return;
      final file = File('build/perf/summary.json');
      await file.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    },
  );
}
