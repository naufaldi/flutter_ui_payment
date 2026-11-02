import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('B2: library motion uses tokens, with documented non-motion times', () {
    const allowed = [
      (
        'actions.dart',
        'waitDuration: const Duration(milliseconds: 500)',
        'tooltip dwell',
      ),
      (
        'actions.dart',
        'Timer(const Duration(milliseconds: 1500)',
        'copy feedback dwell',
      ),
      (
        'controls.dart',
        'this.delay = const Duration(milliseconds: 500)',
        'tooltip dwell',
      ),
      (
        'controls.dart',
        'Timer(const Duration(milliseconds: 1500), _hide)',
        'long-press dwell',
      ),
      (
        'primitives.dart',
        'Timer.periodic(const Duration(seconds: 1)',
        'countdown tick',
      ),
      (
        'interaction.dart',
        'Timer(Duration(milliseconds: ms), dismiss)',
        'toast reading time',
      ),
      ('video.dart', 'posMs.round()', 'media position'),
      ('video.dart', 'ms.round()', 'media seek time'),
      ('payment_motion.dart', '_d(int ms)', 'token definitions'),
    ];
    final violations = <String>[];
    final seen = <int>{};
    for (final file
        in Directory('lib/src')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('Curves.') ||
            line.contains('kThemeAnimationDuration')) {
          violations.add('${file.path}:${i + 1}: $line');
        }
        if (!RegExp(r'Duration\((milliseconds|seconds):').hasMatch(line)) {
          continue;
        }
        var permitted = false;
        for (var a = 0; a < allowed.length; a++) {
          final (name, substring, reason) = allowed[a];
          if (file.uri.pathSegments.last == name && line.contains(substring)) {
            permitted = true;
            seen.add(a);
            expect(reason, isNotEmpty);
          }
        }
        if (!permitted) violations.add('${file.path}:${i + 1}: $line');
      }
    }
    expect(
      seen,
      containsAll(List.generate(allowed.length, (i) => i)),
      reason: 'Keep the allowlist tied to real source',
    );
    expect(violations, isEmpty);
  });
}
