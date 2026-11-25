import 'dart:ui';

double? percentile(List<double> values, double p) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final index = ((p / 100) * (sorted.length - 1)).round();
  return sorted[index];
}

double durationToMilliseconds(Duration duration) =>
    duration.inMicroseconds / 1000;

class ScrollPositionSample {
  const ScrollPositionSample({
    required this.buildStartUs,
    required this.pixels,
  });

  final int buildStartUs;
  final double pixels;

  Map<String, Object?> toJson() => {
    'build_start_us': buildStartUs,
    'pixels': pixels,
  };
}

/// Returns the engine build-start timestamps of frames whose position at the
/// end of the frame differed from the position at the end of the frame before
/// it. [initialPixels] is the stable position before probing started.
List<int> scrollChangingBuildStarts(
  List<ScrollPositionSample> samples, {
  required double initialPixels,
}) {
  final sorted = [...samples]
    ..sort((a, b) => a.buildStartUs.compareTo(b.buildStartUs));
  final changed = <int>[];
  var previous = initialPixels;
  var lastTimestamp = -1;
  for (final sample in sorted) {
    if (sample.buildStartUs == lastTimestamp) continue;
    lastTimestamp = sample.buildStartUs;
    if (sample.pixels != previous) changed.add(sample.buildStartUs);
    previous = sample.pixels;
  }
  return changed;
}

class FrameTimingBag {
  final byBuildStart = <int, FrameTiming>{};
  var batchCount = 0;
  var receivedFrameCount = 0;
  var duplicateFrameCount = 0;

  void addBatch(List<FrameTiming> batch) {
    batchCount++;
    for (final frame in batch) {
      receivedFrameCount++;
      final key = frame.timestampInMicroseconds(FramePhase.buildStart);
      if (byBuildStart.containsKey(key)) duplicateFrameCount++;
      byBuildStart[key] = frame;
    }
  }

  List<int> missingBuildStarts(Iterable<int> buildStarts) => [
    for (final start in buildStarts)
      if (!byBuildStart.containsKey(start)) start,
  ];
}

class ScrollFrameMeasurement {
  const ScrollFrameMeasurement({
    required this.buildStartUs,
    required this.pixels,
    required this.scrollDeltaDp,
    required this.timing,
  });

  final int buildStartUs;
  final double pixels;
  final double scrollDeltaDp;
  final FrameTiming timing;

  Map<String, Object?> toJson() => {
    'build_start_us': buildStartUs,
    'frame_number': timing.frameNumber,
    'pixels': pixels,
    'scroll_delta_dp': scrollDeltaDp,
    'build_ms': durationToMilliseconds(timing.buildDuration),
    'raster_ms': durationToMilliseconds(timing.rasterDuration),
    'raster_finish_us': timing.timestampInMicroseconds(FramePhase.rasterFinish),
  };
}

class ScrollTimingMatch {
  const ScrollTimingMatch({
    required this.measurements,
    required this.missingBuildStarts,
    required this.scrollChangingFrameCount,
    required this.probedFrameCount,
  });

  final List<ScrollFrameMeasurement> measurements;
  final List<int> missingBuildStarts;
  final int scrollChangingFrameCount;
  final int probedFrameCount;

  bool get complete => missingBuildStarts.isEmpty;
}

ScrollTimingMatch matchScrollTimings(
  List<ScrollPositionSample> samples,
  FrameTimingBag timings, {
  required double initialPixels,
}) {
  final sorted = [...samples]
    ..sort((a, b) => a.buildStartUs.compareTo(b.buildStartUs));
  final measurements = <ScrollFrameMeasurement>[];
  final missing = <int>[];
  var previous = initialPixels;
  var lastTimestamp = -1;
  var scrollChangingCount = 0;
  for (final sample in sorted) {
    if (sample.buildStartUs == lastTimestamp) continue;
    lastTimestamp = sample.buildStartUs;
    final delta = sample.pixels - previous;
    previous = sample.pixels;
    if (delta == 0) continue;
    scrollChangingCount++;
    final timing = timings.byBuildStart[sample.buildStartUs];
    if (timing == null) {
      missing.add(sample.buildStartUs);
    } else {
      measurements.add(
        ScrollFrameMeasurement(
          buildStartUs: sample.buildStartUs,
          pixels: sample.pixels,
          scrollDeltaDp: delta,
          timing: timing,
        ),
      );
    }
  }
  return ScrollTimingMatch(
    measurements: measurements,
    missingBuildStarts: missing,
    scrollChangingFrameCount: scrollChangingCount,
    probedFrameCount: sorted.length,
  );
}

Map<String, Object?> frameTimingStats(
  List<FrameTiming> frames, {
  required double refreshHz,
}) {
  final build = [
    for (final frame in frames) durationToMilliseconds(frame.buildDuration),
  ];
  final raster = [
    for (final frame in frames) durationToMilliseconds(frame.rasterDuration),
  ];
  final budget = 1000 / refreshHz;
  final buildOver = build.where((duration) => duration > budget).length;
  final rasterOver = raster.where((duration) => duration > budget).length;
  final eitherOver = frames
      .where(
        (frame) =>
            durationToMilliseconds(frame.buildDuration) > budget ||
            durationToMilliseconds(frame.rasterDuration) > budget,
      )
      .length;
  double? share(int count) => frames.isEmpty ? null : count / frames.length;
  return {
    'frames': frames.length,
    'refresh_budget_ms': budget,
    'build_p50_ms': percentile(build, 50),
    'build_p95_ms': percentile(build, 95),
    'build_max_ms': percentile(build, 100),
    'raster_p50_ms': percentile(raster, 50),
    'raster_p95_ms': percentile(raster, 95),
    'raster_max_ms': percentile(raster, 100),
    'build_over_budget_count': buildOver,
    'build_over_budget_share': share(buildOver),
    'raster_over_budget_count': rasterOver,
    'raster_over_budget_share': share(rasterOver),
    'either_stage_over_budget_count': eitherOver,
    'either_stage_over_budget_share': share(eitherOver),
  };
}

Map<String, Object?> summarizeActionSamples(
  List<Map<String, Object?>> samples,
) {
  List<double> values(String key) => [
    for (final sample in samples)
      if (sample[key] is double) sample[key]! as double,
  ];
  return {
    'sample_count': samples.length,
    'tap_dispatch_ms': values('tap_dispatch_ms'),
    'tap_dispatch_p50_ms': percentile(values('tap_dispatch_ms'), 50),
    'tap_dispatch_p95_ms': percentile(values('tap_dispatch_ms'), 95),
    'first_frame_build_ms': values('first_frame_build_ms'),
    'first_frame_build_p50_ms': percentile(values('first_frame_build_ms'), 50),
    'first_frame_raster_ms': values('first_frame_raster_ms'),
    'first_frame_raster_p50_ms': percentile(
      values('first_frame_raster_ms'),
      50,
    ),
    'samples': samples,
  };
}

class ObservedSpecimen {
  const ObservedSpecimen({
    required this.name,
    required this.documentTop,
    required this.height,
    required this.width,
  });

  final String name;
  final double documentTop;
  final double height;
  final double width;
}

class ControlItemSpec {
  const ControlItemSpec({
    required this.kind,
    required this.height,
    required this.width,
    this.name,
  });

  final String kind;
  final double height;
  final double width;
  final String? name;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'height': height,
    'width': width,
    if (name != null) 'name': name,
  };
}

/// Builds a plain-list geometry plan in document order. Gaps left by specimens
/// not observed in the sampled pass remain explicit filler so the control uses
/// the same offsets even when the observation pass is incomplete.
List<ControlItemSpec> buildControlItems(
  List<ObservedSpecimen> specimens, {
  required double topPadding,
  required double bottomPadding,
  required double targetContentHeight,
}) {
  if (specimens.isEmpty) return const [];
  final sorted = [...specimens]
    ..sort((a, b) => a.documentTop.compareTo(b.documentTop));
  final fallbackWidth = sorted
      .map((specimen) => specimen.width)
      .reduce((a, b) => a > b ? a : b);
  final items = <ControlItemSpec>[];
  var cursor = topPadding;
  var fillerCount = 0;
  void filler(double height) {
    if (height <= 0.01) return;
    fillerCount++;
    items.add(
      ControlItemSpec(
        kind: 'geometry_filler',
        height: height,
        width: fallbackWidth,
        name: 'filler_$fillerCount',
      ),
    );
  }

  for (final specimen in sorted) {
    filler(specimen.documentTop - cursor);
    items.add(
      ControlItemSpec(
        kind: 'plain_material_item',
        height: specimen.height,
        width: specimen.width,
        name: specimen.name,
      ),
    );
    final bottom = specimen.documentTop + specimen.height;
    if (bottom > cursor) cursor = bottom;
  }
  filler(targetContentHeight - bottomPadding - cursor);
  return items;
}
