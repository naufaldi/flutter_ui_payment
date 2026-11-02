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
      // A new first image replaces its whole set: drop continuations
      // (`<name>_partN`, D90) left by an earlier, longer capture. The test
      // reports a specimen's parts right after its first image.
      if (!RegExp(r'_part\d+$').hasMatch(name)) {
        final stale = RegExp(
          '^${RegExp.escape(name)}'
          r'_part\d+\.png$',
        );
        for (final entry in file.parent.listSync()) {
          final base = entry.uri.pathSegments.last;
          if (entry is File && stale.hasMatch(base)) entry.deleteSync();
        }
      }
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
