import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui_example/main.dart';

import 'navigation_perf_model.dart';
import 'support.dart';

const harnessRevision = 'frame-matched-control-v1';
const sourceSha = String.fromEnvironment('SOURCE_SHA', defaultValue: 'unknown');
const sourceDirty = String.fromEnvironment(
  'SOURCE_DIRTY',
  defaultValue: 'unknown',
);
const perfLabel = String.fromEnvironment('PERF_LABEL', defaultValue: 'unknown');
const controlListKey = PageStorageKey('material-control-list');

/// Profile-mode Gallery navigation and scrolling measurements for issue #393.
///
/// Scroll timing is restricted to frames whose measured scroll offset changed.
/// The frame probe reads [SchedulerBinding.currentSystemFrameTimeStamp], the
/// raw timestamp the engine passed to `onBeginFrame`; `FrameTiming` documents
/// the same value as `FramePhase.buildStart`, so the match is exact rather than
/// a wall-clock window guess. Raster finish remains before presentation: these
/// are comparative stage timings, never delivered-FPS claims.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(Duration duration) => Future<void>.delayed(duration);

  testWidgets('profile gallery navigation and frame-matched scrolling', (
    tester,
  ) async {
    final refreshHz =
        PlatformDispatcher.instance.views.first.display.refreshRate;
    final results = <String, Object?>{
      'platform': Platform.operatingSystem,
      'os': Platform.operatingSystemVersion,
      'build_mode': kProfileMode
          ? 'profile'
          : (kReleaseMode ? 'release' : 'debug'),
      'refresh_hz': refreshHz.isFinite ? refreshHz : null,
      'viewport_logical_width':
          tester.view.physicalSize.width / tester.view.devicePixelRatio,
      'viewport_logical_height':
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
      'device_pixel_ratio': tester.view.devicePixelRatio,
      'provenance': {
        'source_sha': sourceSha,
        'source_dirty': sourceDirty,
        'run_label': perfLabel,
        'harness_revision': harnessRevision,
        'driver_path': 'example/integration_test/navigation_perf_test.dart',
        'comparison_requirement':
            'baseline and candidate runs must use this identical file and pass their checkout SHA in SOURCE_SHA',
      },
      'frame_matching_clock':
          'scroll frames are sampled after layout in a post-frame callback keyed by SchedulerBinding.currentSystemFrameTimeStamp; FrameTiming documents that same raw onBeginFrame timestamp as FramePhase.buildStart',
      'latency_measurement_limit':
          'tap dispatch duration uses one local monotonic Stopwatch; no action-to-raster latency is reported because Flutter does not document Timeline.now and FrameTiming as the same clock, and raster finish remains before presentation in any case',
    };

    Map<String, Object?> rectJson(Rect rect) => {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };

    ScrollPosition scrollPosition(Finder scrollable) => tester
        .state<ScrollableState>(
          find
              .descendant(of: scrollable, matching: find.byType(Scrollable))
              .first,
        )
        .position;

    Future<void> waitForScrollQuiet(ScrollPosition position) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      var stableSamples = 0;
      var last = position.pixels;
      while (stableSamples < 6 && DateTime.now().isBefore(deadline)) {
        await wait(const Duration(milliseconds: 30));
        if ((position.pixels - last).abs() < 0.001) {
          stableSamples++;
        } else {
          stableSamples = 0;
        }
        last = position.pixels;
      }
      if (stableSamples < 6) {
        throw TestFailure('Scroll position did not become quiet within 5 s');
      }
    }

    Future<int> firstDestinationFrameBuildStart(
      bool Function() destinationReady,
      String destinationName,
    ) {
      final completer = Completer<int>();
      var active = true;
      void sample(Duration _) {
        if (!active || completer.isCompleted) return;
        final timestamp = SchedulerBinding
            .instance
            .currentSystemFrameTimeStamp
            .inMicroseconds;
        if (destinationReady()) {
          active = false;
          completer.complete(timestamp);
        } else {
          SchedulerBinding.instance.addPostFrameCallback(sample);
        }
      }

      SchedulerBinding.instance.addPostFrameCallback(sample);
      return completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          active = false;
          throw TestFailure(
            'No completed frame showed $destinationName within 2 s',
          );
        },
      );
    }

    Future<Map<String, Object?>> measureAction(
      Future<void> Function() action, {
      required bool Function() destinationReady,
      required String destinationName,
    }) async {
      final sink = _FrameTimingSink();
      SchedulerBinding.instance.addTimingsCallback(sink.collect);
      try {
        await wait(const Duration(milliseconds: 500));
        final dispatch = Stopwatch()..start();
        await action();
        dispatch.stop();
        final buildStart = await firstDestinationFrameBuildStart(
          destinationReady,
          destinationName,
        );
        final drained = await sink.drainBuildStarts({buildStart});
        if (!drained) {
          throw TestFailure(
            'FrameTiming batch did not drain for the first $destinationName frame',
          );
        }
        final first = sink.bag.byBuildStart[buildStart]!;
        return {
          'tap_dispatch_ms': durationToMilliseconds(dispatch.elapsed),
          'first_frame_build_ms': durationToMilliseconds(first.buildDuration),
          'first_frame_raster_ms': durationToMilliseconds(first.rasterDuration),
          'first_frame_build_start_us': buildStart,
          'first_frame_number': first.frameNumber,
          'destination_frame_match':
              'first completed frame whose post-frame state satisfied destinationReady',
          'timing_callback_drain_complete': drained,
          'timing_batches': sink.bag.batchCount,
          'timing_frames_received': sink.bag.receivedFrameCount,
          'duplicate_timing_frames': sink.bag.duplicateFrameCount,
        };
      } finally {
        SchedulerBinding.instance.removeTimingsCallback(sink.collect);
      }
    }

    Future<void> dragDown(
      Finder scrollable, {
      required int drags,
      required double distancePerDrag,
    }) async {
      final rect = tester.getRect(scrollable);
      for (var drag = 0; drag < drags; drag++) {
        final gesture = await tester.startGesture(
          Offset(rect.right - 10, rect.bottom - 72),
        );
        var gestureMicros = 0;
        for (var step = 0; step < 10; step++) {
          gestureMicros += 35000;
          await gesture.moveBy(
            Offset(0, -distancePerDrag / 10),
            timeStamp: Duration(microseconds: gestureMicros),
          );
          await wait(const Duration(milliseconds: 35));
        }
        await wait(const Duration(milliseconds: 80));
        gestureMicros += 80000;
        await gesture.up(timeStamp: Duration(microseconds: gestureMicros));
        await wait(const Duration(milliseconds: 120));
      }
    }

    Future<Map<String, Object?>> profileScroll(
      Finder scrollable, {
      required String workloadName,
    }) async {
      final position = scrollPosition(scrollable);
      final viewport = tester.getRect(scrollable);
      position.jumpTo(position.minScrollExtent);
      await tester.pump();
      await waitForScrollQuiet(position);
      final before = position.pixels;
      final sink = _FrameTimingSink();
      final probe = _ScrollPositionProbe(position);
      SchedulerBinding.instance.addTimingsCallback(sink.collect);
      probe.start();
      try {
        await dragDown(scrollable, drags: 3, distancePerDrag: 350);
        await waitForScrollQuiet(position);
        probe.stop();
        final changed = scrollChangingBuildStarts(
          probe.samples,
          initialPixels: before,
        );
        if (changed.isEmpty) {
          throw TestFailure('$workloadName produced no scroll-changing frames');
        }
        final drained = await sink.drainBuildStarts(changed);
        final match = matchScrollTimings(
          probe.samples,
          sink.bag,
          initialPixels: before,
        );
        if (!drained || !match.complete) {
          throw TestFailure(
            '$workloadName FrameTiming drain incomplete: missing ${match.missingBuildStarts.length} of ${match.scrollChangingFrameCount} scroll-changing frames',
          );
        }
        final frames = [
          for (final measurement in match.measurements) measurement.timing,
        ];
        final scrollDeltas = [
          for (final measurement in match.measurements)
            measurement.scrollDeltaDp,
        ];
        final positiveDistance = scrollDeltas.fold<double>(
          0,
          (total, delta) => total + math.max(0, delta),
        );
        return {
          ...frameTimingStats(frames, refreshHz: refreshHz),
          'workload': workloadName,
          'scroll_frame_count': match.scrollChangingFrameCount,
          'matched_scroll_frame_count': match.measurements.length,
          'probed_frame_count': match.probedFrameCount,
          'timing_callback_drain_complete': drained && match.complete,
          'timing_batches': sink.bag.batchCount,
          'timing_frames_received': sink.bag.receivedFrameCount,
          'duplicate_timing_frames': sink.bag.duplicateFrameCount,
          'probe_duplicate_frame_timestamps': probe.duplicateTimestamps,
          'requested_scroll_distance_dp': 1050,
          'scroll_start_dp': before,
          'scroll_end_dp': position.pixels,
          'actual_scroll_delta_dp': position.pixels - before,
          'positive_scroll_distance_dp': positiveDistance,
          'max_scroll_extent_dp': position.maxScrollExtent,
          'viewport_rect': rectJson(viewport),
          'gesture_cadence':
              '3 controlled drags; 350 dp each in 10 pointer moves with monotonic synthetic timestamps at 35 ms intervals, 80 ms hold before release, 120 ms between drags',
          'gesture_path':
              'start 10 dp inside the right edge and 72 dp above the bottom of the same scroll viewport; vertical upward path',
          'frame_details': [
            for (final measurement in match.measurements) measurement.toJson(),
          ],
        };
      } finally {
        probe.stop();
        SchedulerBinding.instance.removeTimingsCallback(sink.collect);
      }
    }

    Future<List<Map<String, Object?>>> observeSpecimenIntersections(
      Finder gallery,
      double endOffset,
    ) async {
      final position = scrollPosition(gallery);
      final viewport = tester.getRect(gallery);
      final aggregates = <String, _SpecimenAggregate>{};
      final offsets = <double>{0, endOffset};
      for (var offset = 0.0; offset < endOffset; offset += 50) {
        offsets.add(offset);
      }
      final sortedOffsets = offsets.toList()..sort();
      for (final rawOffset in sortedOffsets) {
        final offset = rawOffset.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        position.jumpTo(offset);
        await tester.pump();
        await wait(const Duration(milliseconds: 25));
        for (final element in find.byElementPredicate((element) {
          final key = element.widget.key;
          return key is ValueKey<String> && key.value.startsWith('specimen:');
        }).evaluate()) {
          final renderObject = element.renderObject;
          if (renderObject is! RenderBox ||
              !renderObject.attached ||
              !renderObject.hasSize) {
            continue;
          }
          // `_Entry`'s key is on the column inside its bottom padding. Prefer
          // the immediate RenderPadding parent when it is exactly that entry
          // slot so control item heights include the same trailing whitespace.
          var box = renderObject;
          final parent = renderObject.parent;
          if (parent is RenderBox &&
              (parent.size.height - renderObject.size.height - 32).abs() < 1) {
            box = parent;
          }
          final rect = box.localToGlobal(Offset.zero) & box.size;
          final intersects =
              rect.bottom > viewport.top &&
              rect.top < viewport.bottom &&
              rect.right > viewport.left &&
              rect.left < viewport.right;
          if (!intersects) continue;
          final key = (element.widget.key! as ValueKey<String>).value;
          final name = key.substring('specimen:'.length);
          final documentTop = position.pixels + rect.top - viewport.top;
          aggregates
              .putIfAbsent(name, () => _SpecimenAggregate(name))
              .add(
                documentTop: documentTop,
                height: rect.height,
                width: rect.width,
                offset: position.pixels,
              );
        }
      }
      position.jumpTo(position.minScrollExtent);
      await tester.pump();
      final observed = aggregates.values.toList()
        ..sort((a, b) => a.minDocumentTop.compareTo(b.minDocumentTop));
      return [for (final item in observed) item.toJson()];
    }

    Finder tabLabel(String label) => find
        .descendant(of: find.byType(NavigationBar), matching: find.text(label))
        .first;

    Future<void> tapTab(String label) async {
      await tester.tap(tabLabel(label));
      await settle(tester);
    }

    Future<void> openDrawer() async {
      await tester.tap(find.byTooltip('Open navigation'));
      await settle(tester);
      expect(find.byType(Drawer), findsOneWidget);
    }

    Future<void> selectGallerySection(String label) async {
      await openDrawer();
      final item = find.descendant(
        of: find.byType(Drawer),
        matching: find.text(label),
      );
      await tester.tap(item);
      await settle(tester);
    }

    final app = await launch(
      tester,
      latencyScale: 1,
      settings: const DemoSettings(locale: Locale('en'), textScale: 1),
    );
    await pumpUntil(tester, () => !app.coordinator.starting);
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);

    results['first_demo_to_gallery'] = await measureAction(
      () => tester.tap(tabLabel('Gallery')),
      destinationReady: () =>
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex ==
          2,
      destinationName: 'Gallery tab',
    );
    await settle(tester);

    await openDrawer();
    final viewsItem = find.descendant(
      of: find.byType(Drawer),
      matching: find.text('Views & pages'),
    );
    results['first_gallery_views_payment_context'] = await measureAction(
      () => tester.tap(viewsItem),
      destinationReady: () => find
          .byKey(const ValueKey('specimen:PaymentContextView · variants'))
          .evaluate()
          .isNotEmpty,
      destinationName: 'Views & pages section',
    );
    await settle(tester);

    final warmedTabs = <Map<String, Object?>>[];
    for (var i = 0; i < 5; i++) {
      await tapTab('Demo');
      final sample = await measureAction(
        () => tester.tap(tabLabel('Gallery')),
        destinationReady: () =>
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex ==
            2,
        destinationName: 'warmed Gallery tab',
      );
      warmedTabs.add(sample);
      await settle(tester);
    }
    results['warmed_demo_to_gallery'] = summarizeActionSamples(warmedTabs);

    final warmedViews = <Map<String, Object?>>[];
    for (var i = 0; i < 5; i++) {
      await selectGallerySection('Foundation');
      await openDrawer();
      final item = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Views & pages'),
      );
      final sample = await measureAction(
        () => tester.tap(item),
        destinationReady: () => find
            .byKey(const ValueKey('specimen:PaymentContextView · variants'))
            .evaluate()
            .isNotEmpty,
        destinationName: 'warmed Views & pages section',
      );
      warmedViews.add(sample);
      await settle(tester);
    }
    results['warmed_gallery_views_payment_context'] = summarizeActionSamples(
      warmedViews,
    );

    final gallery = galleryList();
    final galleryRect = tester.getRect(gallery);
    results['gallery_views_scroll_first_reveal'] = await profileScroll(
      gallery,
      workloadName: 'gallery_views_first_reveal',
    );
    results['gallery_views_scroll_repeat'] = await profileScroll(
      gallery,
      workloadName: 'gallery_views_repeat_after_reveal',
    );

    final firstScroll =
        results['gallery_views_scroll_first_reveal']! as Map<String, Object?>;
    final repeatScroll =
        results['gallery_views_scroll_repeat']! as Map<String, Object?>;
    final endOffset = firstScroll['scroll_end_dp']! as double;
    final specimens = await observeSpecimenIntersections(gallery, endOffset);
    if (specimens.isEmpty) {
      throw TestFailure('No gallery specimen intersections were observed');
    }
    results['gallery_views_observed_intersections'] = specimens;
    final maxDocumentTopSpread = specimens.fold<double>(
      0,
      (largest, item) =>
          math.max(largest, item['document_top_spread_dp']! as double),
    );
    if (maxDocumentTopSpread > 2) {
      throw TestFailure(
        'Specimen document positions were unstable across observation passes: spread $maxDocumentTopSpread dp',
      );
    }
    results['specimen_intersection_sampling'] = {
      'method':
          'post-measurement replay of the same scroll-offset path at 50 dp intervals; only specimens whose laid-out rects intersected the gallery viewport are listed',
      'scroll_start_dp': 0,
      'scroll_end_dp': endOffset,
      'sample_step_dp': 50,
      'observed_specimen_count': specimens.length,
      'max_document_top_spread_dp': maxDocumentTopSpread,
    };

    final observedSpecimens = [
      for (final item in specimens)
        ObservedSpecimen(
          name: item['name']! as String,
          documentTop: item['document_top_dp']! as double,
          height: item['height_max_dp']! as double,
          width: item['width_max_dp']! as double,
        ),
    ];
    final galleryPosition = scrollPosition(gallery);
    final targetContentHeight = math.max(
      galleryPosition.maxScrollExtent + galleryRect.height,
      endOffset + galleryRect.height + 500,
    );
    final controlItems = buildControlItems(
      observedSpecimens,
      topPadding: 8,
      bottomPadding: 32,
      targetContentHeight: targetContentHeight,
    );
    results['material_control_geometry'] = {
      'source': 'observed gallery specimen rects in document order',
      'target_content_height_dp': targetContentHeight,
      'gallery_max_scroll_extent_after_run_dp': galleryPosition.maxScrollExtent,
      'item_count': controlItems.length,
      'plain_material_item_count': controlItems
          .where((item) => item.kind == 'plain_material_item')
          .length,
      'geometry_filler_count': controlItems
          .where((item) => item.kind == 'geometry_filler')
          .length,
      'items': [for (final item in controlItems) item.toJson()],
    };

    await tester.pumpWidget(_MaterialControlApp(items: controlItems));
    await settle(tester);
    final control = find.byKey(controlListKey);
    expect(control, findsOneWidget);
    final controlRect = tester.getRect(control);
    final shellDelta =
        (controlRect.width - galleryRect.width).abs() +
        (controlRect.height - galleryRect.height).abs();
    if (shellDelta > 1) {
      throw TestFailure(
        'Material control viewport does not match the gallery shell: delta $shellDelta dp',
      );
    }
    results['material_control_shell_match'] = {
      'gallery_viewport_rect': rectJson(galleryRect),
      'control_viewport_rect': rectJson(controlRect),
      'width_height_delta_dp': shellDelta,
      'requested_same_scroll_offsets_distance_gestures_and_path': true,
    };

    results['material_control_scroll'] = await profileScroll(
      control,
      workloadName: 'plain_material_control',
    );
    final controlScroll =
        results['material_control_scroll']! as Map<String, Object?>;
    final actualScrollDeltaDifference =
        ((repeatScroll['actual_scroll_delta_dp']! as double) -
                (controlScroll['actual_scroll_delta_dp']! as double))
            .abs();
    final maxScrollExtentDifference =
        ((repeatScroll['max_scroll_extent_dp']! as double) -
                (controlScroll['max_scroll_extent_dp']! as double))
            .abs();
    results['gallery_control_comparison'] = {
      'same_session': true,
      'control_kind':
          'plain Material fixed-height list using observed gallery item geometry',
      'gallery_repeat_actual_scroll_delta_dp':
          repeatScroll['actual_scroll_delta_dp'],
      'control_actual_scroll_delta_dp': controlScroll['actual_scroll_delta_dp'],
      'actual_scroll_delta_difference_dp': actualScrollDeltaDifference,
      'max_scroll_extent_difference_dp': maxScrollExtentDifference,
      'gallery_repeat_raster_p50_minus_control_raster_p50_ms':
          (repeatScroll['raster_p50_ms'] as double?) == null ||
              (controlScroll['raster_p50_ms'] as double?) == null
          ? null
          : (repeatScroll['raster_p50_ms']! as double) -
                (controlScroll['raster_p50_ms']! as double),
      'gallery_repeat_build_p50_minus_control_build_p50_ms':
          (repeatScroll['build_p50_ms'] as double?) == null ||
              (controlScroll['build_p50_ms'] as double?) == null
          ? null
          : (repeatScroll['build_p50_ms']! as double) -
                (controlScroll['build_p50_ms']! as double),
      'interpretation_limit':
          'the control isolates shared input/list/shell cost in this session only; a meaningful excess motivates a targeted experiment and does not by itself accept production raster changes',
    };

    expect(tester.takeException(), isNull);
    binding.reportData = {'gallery_navigation': results};
  });
}

class _FrameTimingSink {
  final bag = FrameTimingBag();

  void collect(List<FrameTiming> batch) => bag.addBatch(batch);

  Future<bool> drainBuildStarts(
    Iterable<int> buildStarts, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (bag.missingBuildStarts(buildStarts).isNotEmpty &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return bag.missingBuildStarts(buildStarts).isEmpty;
  }
}

class _ScrollPositionProbe {
  _ScrollPositionProbe(this.position);

  final ScrollPosition position;
  final samples = <ScrollPositionSample>[];
  var duplicateTimestamps = 0;
  var _active = false;

  void start() {
    if (_active) return;
    _active = true;
    SchedulerBinding.instance.addPostFrameCallback(_sample);
  }

  void stop() => _active = false;

  void _sample(Duration _) {
    if (!_active) return;
    final timestamp =
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    if (samples.isNotEmpty && samples.last.buildStartUs == timestamp) {
      duplicateTimestamps++;
    } else {
      samples.add(
        ScrollPositionSample(buildStartUs: timestamp, pixels: position.pixels),
      );
    }
    SchedulerBinding.instance.addPostFrameCallback(_sample);
  }
}

class _SpecimenAggregate {
  _SpecimenAggregate(this.name);

  final String name;
  var minDocumentTop = double.infinity;
  var maxDocumentTop = double.negativeInfinity;
  var heightMax = 0.0;
  var widthMax = 0.0;
  var intersectionSamples = 0;
  final observedAtOffsets = <double>[];

  void add({
    required double documentTop,
    required double height,
    required double width,
    required double offset,
  }) {
    minDocumentTop = math.min(minDocumentTop, documentTop);
    maxDocumentTop = math.max(maxDocumentTop, documentTop);
    heightMax = math.max(heightMax, height);
    widthMax = math.max(widthMax, width);
    intersectionSamples++;
    if (!observedAtOffsets.contains(offset)) observedAtOffsets.add(offset);
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'document_top_dp': minDocumentTop,
    'document_top_spread_dp': maxDocumentTop - minDocumentTop,
    'height_max_dp': heightMax,
    'width_max_dp': widthMax,
    'intersection_sample_count': intersectionSamples,
    'observed_at_scroll_offsets_dp': observedAtOffsets,
  };
}

class _MaterialControlApp extends StatelessWidget {
  const _MaterialControlApp({required this.items});

  final List<ControlItemSpec> items;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Open navigation',
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          title: const Text('Gallery'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.tune),
              onPressed: () {},
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 2,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'Demo',
            ),
            NavigationDestination(
              icon: Icon(Icons.rule_folder_outlined),
              selectedIcon: Icon(Icons.rule_folder),
              label: 'Scenarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.widgets_outlined),
              selectedIcon: Icon(Icons.widgets),
              label: 'Gallery',
            ),
          ],
        ),
        body: SafeArea(
          child: ColoredBox(
            color: const Color(0xfff5f5f5),
            child: ListView.builder(
              key: controlListKey,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Center(
                  child: SizedBox(
                    width: item.width,
                    height: item.height,
                    child: item.kind == 'plain_material_item'
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                  color: Color(0xffd0d0d0),
                                ),
                              ),
                              child: Center(
                                child: Text(item.name ?? 'control'),
                              ),
                            ),
                          )
                        : const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
