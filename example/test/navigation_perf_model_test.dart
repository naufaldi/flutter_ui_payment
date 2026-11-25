import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/navigation_perf_model.dart';

FrameTiming timing(
  int buildStart, {
  int buildMicros = 4000,
  int rasterMicros = 6000,
}) => FrameTiming(
  vsyncStart: buildStart - 1000,
  buildStart: buildStart,
  buildFinish: buildStart + buildMicros,
  rasterStart: buildStart + buildMicros + 500,
  rasterFinish: buildStart + buildMicros + 500 + rasterMicros,
  rasterFinishWallTime: buildStart + buildMicros + 500 + rasterMicros,
  frameNumber: buildStart,
);

void main() {
  test('matches FrameTiming only to frames whose scroll offset changed', () {
    final samples = [
      const ScrollPositionSample(buildStartUs: 1000, pixels: 0),
      const ScrollPositionSample(buildStartUs: 2000, pixels: 12),
      const ScrollPositionSample(buildStartUs: 3000, pixels: 12),
      const ScrollPositionSample(buildStartUs: 4000, pixels: 30),
    ];
    expect(scrollChangingBuildStarts(samples, initialPixels: 0), [2000, 4000]);

    final bag = FrameTimingBag()
      ..addBatch([timing(1000), timing(2000)])
      ..addBatch([timing(3000), timing(4000)]);
    final match = matchScrollTimings(samples, bag, initialPixels: 0);

    expect(match.complete, isTrue);
    expect(match.scrollChangingFrameCount, 2);
    expect(match.measurements.map((frame) => frame.buildStartUs), [2000, 4000]);
    expect(match.measurements.map((frame) => frame.scrollDeltaDp), [12, 18]);
  });

  test(
    'reports undrained timing batches as missing instead of claiming them',
    () {
      final samples = [
        const ScrollPositionSample(buildStartUs: 2000, pixels: 12),
        const ScrollPositionSample(buildStartUs: 4000, pixels: 30),
      ];
      final bag = FrameTimingBag()..addBatch([timing(2000)]);
      final match = matchScrollTimings(samples, bag, initialPixels: 0);

      expect(match.complete, isFalse);
      expect(match.missingBuildStarts, [4000]);
      expect(match.measurements, hasLength(1));
    },
  );

  test('frame statistics describe the matched frame set', () {
    final stats = frameTimingStats([
      timing(1000, buildMicros: 4000, rasterMicros: 8000),
      timing(2000, buildMicros: 20000, rasterMicros: 6000),
    ], refreshHz: 60);

    expect(stats['frames'], 2);
    expect(stats['build_over_budget_count'], 1);
    expect(stats['raster_over_budget_count'], 0);
    expect(stats['either_stage_over_budget_count'], 1);
    expect(stats['raster_p50_ms'], 8.0);
  });

  test('action summaries avoid cross-clock action-to-raster claims', () {
    final summary = summarizeActionSamples(const [
      {
        'tap_dispatch_ms': 1.0,
        'first_frame_build_ms': 4.0,
        'first_frame_raster_ms': 6.0,
      },
      {
        'tap_dispatch_ms': 3.0,
        'first_frame_build_ms': 8.0,
        'first_frame_raster_ms': 10.0,
      },
    ]);

    expect(summary.containsKey('action_to_first_raster_ms'), isFalse);
    expect(summary['tap_dispatch_p50_ms'], 3.0);
    expect(summary['first_frame_build_p50_ms'], 8.0);
    expect(summary['first_frame_raster_p50_ms'], 10.0);
  });

  test('control geometry preserves observed heights and explicit gaps', () {
    final items = buildControlItems(
      const [
        ObservedSpecimen(
          name: 'first',
          documentTop: 8,
          height: 100,
          width: 328,
        ),
        ObservedSpecimen(
          name: 'third',
          documentTop: 158,
          height: 80,
          width: 328,
        ),
      ],
      topPadding: 8,
      bottomPadding: 32,
      targetContentHeight: 400,
    );

    expect(items.map((item) => item.kind), [
      'plain_material_item',
      'geometry_filler',
      'plain_material_item',
      'geometry_filler',
    ]);
    expect(items.map((item) => item.height), [100, 50, 80, 130]);
  });
}
