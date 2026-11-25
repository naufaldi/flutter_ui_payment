import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/navigation_perf_model.dart';

FrameTiming timing(
  int frameNumber, {
  int systemFrameTimestamp = 0,
  int buildMicros = 4000,
  int rasterMicros = 6000,
}) {
  final buildStart = systemFrameTimestamp + 700;
  return FrameTiming(
    vsyncStart: buildStart - 1000,
    buildStart: buildStart,
    buildFinish: buildStart + buildMicros,
    rasterStart: buildStart + buildMicros + 500,
    rasterFinish: buildStart + buildMicros + 500 + rasterMicros,
    rasterFinishWallTime: buildStart + buildMicros + 500 + rasterMicros,
    frameNumber: frameNumber,
  );
}

ScrollPositionSample sample(
  int frameNumber,
  double pixels, {
  int systemFrameTimestamp = 0,
}) => ScrollPositionSample(
  frameNumber: frameNumber,
  systemFrameTimestampUs: systemFrameTimestamp,
  pixels: pixels,
);

void main() {
  test('matches FrameTiming only to frames whose scroll offset changed', () {
    final samples = [
      sample(10, 0, systemFrameTimestamp: 1000),
      sample(11, 12, systemFrameTimestamp: 2000),
      sample(12, 12, systemFrameTimestamp: 3000),
      sample(13, 30, systemFrameTimestamp: 4000),
    ];
    expect(scrollChangingFrameNumbers(samples, initialPixels: 0), [11, 13]);

    final bag = FrameTimingBag()
      ..addBatch([
        timing(10, systemFrameTimestamp: 1000),
        timing(11, systemFrameTimestamp: 2000),
      ])
      ..addBatch([
        timing(12, systemFrameTimestamp: 3000),
        timing(13, systemFrameTimestamp: 4000),
      ]);
    final match = matchScrollTimings(samples, bag, initialPixels: 0);

    expect(match.complete, isTrue);
    expect(match.scrollChangingFrameCount, 2);
    expect(match.measurements.map((frame) => frame.frameNumber), [11, 13]);
    expect(match.measurements.map((frame) => frame.scrollDeltaDp), [12, 18]);
    expect(
      match.measurements.first.timing.timestampInMicroseconds(
        FramePhase.buildStart,
      ),
      2700,
    );
  });

  test(
    'reports undrained timing batches as missing instead of claiming them',
    () {
      final samples = [sample(11, 12), sample(13, 30)];
      final bag = FrameTimingBag()..addBatch([timing(11)]);
      final match = matchScrollTimings(samples, bag, initialPixels: 0);

      expect(match.complete, isFalse);
      expect(match.missingFrameNumbers, [13]);
      expect(match.measurements, hasLength(1));
    },
  );

  test('frame-number validation summarizes observed exact matches', () {
    final samples = [
      sample(11, 12, systemFrameTimestamp: 2000),
      sample(12, 30, systemFrameTimestamp: 3000),
    ];
    final bag = FrameTimingBag()
      ..addBatch([
        timing(11, systemFrameTimestamp: 2000),
        timing(12, systemFrameTimestamp: 3000),
      ]);
    final match = matchScrollTimings(samples, bag, initialPixels: 0);
    final validation = frameNumberMatchValidation(
      match.measurements,
      missingFrameCount: match.missingFrameNumbers.length,
      probedFrameCount: match.probedFrameCount,
    );

    expect(validation['matched_frame_count'], 2);
    expect(validation['frame_numbers_strictly_increasing'], isTrue);
    expect(
      validation['build_start_minus_system_frame_timestamp_us_min'],
      700.0,
    );
  });

  test('frame statistics describe the matched frame set', () {
    final stats = frameTimingStats([
      timing(1, buildMicros: 4000, rasterMicros: 8000),
      timing(2, buildMicros: 20000, rasterMicros: 6000),
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
