import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/perf_test.dart' show summarize;
import '../integration_test/performance_verdict.dart';

Map<String, Object?> workload({double build = 10, double raster = 15}) => {
  'frames': 400,
  'warm_up_elapsed_ms': 30600,
  'warm_up_iterations': 15,
  'measured_elapsed_ms': 30300,
  'measured_iterations': 15,
  'build_p95_ms': build,
  'raster_p95_ms': raster,
};

Map<String, Object?> summary() => {
  'build_mode': 'profile',
  'refresh_hz': 59.94,
  'checkout': workload(build: 16.699),
  'status': workload(),
  'checkout_text100_diagnostic': workload(build: 42, raster: 43),
  'plain_list_control': workload(build: 42, raster: 43),
};

void main() {
  test('measured p95 includes late finishes but not warm-up frames', () {
    FrameTiming frame(int buildStart, int rasterStart, int finish) =>
        FrameTiming(
          vsyncStart: buildStart,
          buildStart: buildStart,
          buildFinish: buildStart + 1000,
          rasterStart: rasterStart,
          rasterFinish: finish,
          rasterFinishWallTime: finish,
        );

    final metrics = summarize(
      [
        frame(90000, 98000, 105000),
        frame(107000, 110000, 115000),
        frame(195000, 198000, 218000),
        frame(200000, 202000, 222000),
      ],
      start: 100000,
      end: 200000,
    );

    expect(metrics['frames'], 2);
    expect(metrics['raster_p95_ms'], 20);
  });

  test('both workloads pass below budget even with slow controls', () {
    final evidence = summary();
    final verdict = performanceVerdict(evidence);
    expect(verdict['verdict'], 'pass');
    expect(performanceVerdict(evidence), equals(verdict));
  });

  test('each required workload checks build and raster independently', () {
    final verdict = performanceVerdict(
      summary()
        ..['checkout'] = workload(raster: 16.7)
        ..['status'] = workload(build: 16.701),
    );
    expect(verdict['verdict'], 'fail');
    expect(verdict['workloads'], {
      'checkout': {
        'verdict': 'fail',
        'over_budget': ['raster_p95_ms'],
      },
      'status': {
        'verdict': 'fail',
        'over_budget': ['build_p95_ms'],
      },
    });
  });

  test('only a recorded nominal 60 Hz profile run is comparable', () {
    for (final (mode, hz) in [
      ('debug', 60),
      ('release', 60),
      ('profile', 120),
      ('profile', null),
    ]) {
      final evidence = summary()
        ..['build_mode'] = mode
        ..['refresh_hz'] = hz;
      expect(performanceVerdict(evidence)['verdict'], 'inconclusive');
    }
  });

  test('checkout-only evidence is inconclusive even over budget', () {
    final evidence = summary()
      ..remove('status')
      ..['checkout'] = workload(raster: 30);
    final verdict = performanceVerdict(evidence);
    expect(verdict['verdict'], 'inconclusive');
    expect(verdict['workloads'], {
      'checkout': {
        'verdict': 'fail',
        'over_budget': ['raster_p95_ms'],
      },
      'status': {
        'verdict': 'inconclusive',
        'reason': 'Workload evidence is missing.',
      },
    });
  });

  test('missing frame, window, or metric evidence is inconclusive', () {
    for (final (key, value) in <(String, Object?)>[
      ('frames', 0),
      ('warm_up_elapsed_ms', 29999),
      ('measured_elapsed_ms', null),
      ('measured_iterations', 1),
      ('build_p95_ms', null),
      ('raster_p95_ms', double.nan),
    ]) {
      final evidence = summary()..['status'] = (workload()..[key] = value);
      expect(
        performanceVerdict(evidence)['verdict'],
        'inconclusive',
        reason: key,
      );
    }
  });
}
