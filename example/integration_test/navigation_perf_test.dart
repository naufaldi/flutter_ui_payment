import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui_example/main.dart';
import 'package:rakit_ui_example/screens/steps/history_step.dart';

import 'support.dart';

/// Profile-mode navigation and scrolling measurements for issue #393.
///
/// The action latency is tap dispatch end to the raster finish of the first
/// frame whose build started after that dispatch. Raster finish is a proxy for
/// presentation; it is not a delivered-FPS or surface-present measurement.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(Duration d) => Future<void>.delayed(d);

  double? percentile(List<double> values, double p) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final index = ((p / 100) * (sorted.length - 1)).round();
    return sorted[index];
  }

  double ms(int microseconds) => microseconds / 1000;

  Map<String, Object?> frameStats(
    List<FrameTiming> timings, {
    required int start,
    required int end,
    required double refreshHz,
  }) {
    final frames = timings.where((frame) {
      final built = frame.timestampInMicroseconds(FramePhase.buildStart);
      return built >= start && built < end;
    }).toList();
    double durationMs(Duration d) => d.inMicroseconds / 1000;
    final build = [for (final f in frames) durationMs(f.buildDuration)];
    final raster = [for (final f in frames) durationMs(f.rasterDuration)];
    final budget = 1000 / refreshHz;
    final buildOver = build.where((d) => d > budget).length;
    final rasterOver = raster.where((d) => d > budget).length;
    final eitherOver = frames
        .where(
          (f) =>
              durationMs(f.buildDuration) > budget ||
              durationMs(f.rasterDuration) > budget,
        )
        .length;
    double? share(int count) => frames.isEmpty ? null : count / frames.length;
    return {
      'frames': frames.length,
      'window_ms': ((end - start) / 1000).roundToDouble(),
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

  List<Map<String, Object?>> aggregateSamples(
    List<Map<String, Object?>> samples,
  ) => samples;

  Map<String, Object?> summarizeSamples(List<Map<String, Object?>> samples) {
    double? sampleValue(Map<String, Object?> sample, String key) =>
        sample[key] as double?;
    List<double> values(String key) => [
      for (final sample in samples)
        if (sampleValue(sample, key) != null) sampleValue(sample, key)!,
    ];
    return {
      'sample_count': samples.length,
      'action_to_first_raster_ms': values('action_to_first_raster_ms'),
      'action_to_first_raster_p50_ms': percentile(
        values('action_to_first_raster_ms'),
        50,
      ),
      'action_to_first_raster_p95_ms': percentile(
        values('action_to_first_raster_ms'),
        95,
      ),
      'first_frame_build_ms': values('first_frame_build_ms'),
      'first_frame_build_p50_ms': percentile(
        values('first_frame_build_ms'),
        50,
      ),
      'first_frame_raster_ms': values('first_frame_raster_ms'),
      'first_frame_raster_p50_ms': percentile(
        values('first_frame_raster_ms'),
        50,
      ),
      'frames_within_300ms': values('frames_within_300ms'),
      'frames_within_300ms_p50': percentile(values('frames_within_300ms'), 50),
      'history_loaded_after_action_ms': values(
        'history_loaded_after_action_ms',
      ),
      'samples': aggregateSamples(samples),
    };
  }

  testWidgets('profile gallery navigation and scripted scrolling', (
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
      'latency_measurement_limit':
          'action latency ends at FrameTiming rasterFinish, before presentation; frame counts are counts in the scripted window, not delivered FPS',
    };

    Future<Map<String, Object?>> measureAction(
      Future<void> Function() action, {
      required bool Function() destinationReady,
    }) async {
      final timings = <FrameTiming>[];
      void collect(List<FrameTiming> batch) => timings.addAll(batch);
      SchedulerBinding.instance.addTimingsCallback(collect);
      try {
        await wait(const Duration(milliseconds: 500));
        final actionStart = Timeline.now;
        await action();
        final actionEnd = Timeline.now;
        FrameTiming? first;
        final deadline = actionEnd + 2000000;
        while (first == null && Timeline.now < deadline) {
          for (final frame in timings) {
            if (frame.timestampInMicroseconds(FramePhase.buildStart) >=
                actionEnd) {
              first = frame;
              break;
            }
          }
          if (first == null) await wait(const Duration(milliseconds: 1));
        }
        if (first == null) {
          throw TestFailure('No frame started after the measured action');
        }
        final windowEnd = actionEnd + 300000;
        while (Timeline.now < windowEnd + 30000) {
          await wait(const Duration(milliseconds: 5));
        }
        if (!destinationReady()) {
          throw TestFailure(
            'The measured action did not reach its destination',
          );
        }
        final buildStart = first.timestampInMicroseconds(FramePhase.buildStart);
        final rasterFinish = first.timestampInMicroseconds(
          FramePhase.rasterFinish,
        );
        final firstStats = frameStats(
          timings,
          start: actionEnd,
          end: windowEnd,
          refreshHz: refreshHz,
        );
        return {
          ...firstStats,
          'tap_dispatch_ms': ms(actionEnd - actionStart),
          'first_frame_build_start_after_action_ms': ms(buildStart - actionEnd),
          'action_to_first_raster_ms': ms(rasterFinish - actionEnd),
          'first_frame_build_ms': first.buildDuration.inMicroseconds / 1000,
          'first_frame_raster_ms': first.rasterDuration.inMicroseconds / 1000,
          'frames_within_300ms': (firstStats['frames'] as int).toDouble(),
          'action_end_monotonic_us': actionEnd,
        };
      } finally {
        SchedulerBinding.instance.removeTimingsCallback(collect);
      }
    }

    Future<Map<String, Object?>> collectScrollFrames(
      Future<void> Function() workload,
    ) async {
      final timings = <FrameTiming>[];
      void collect(List<FrameTiming> batch) => timings.addAll(batch);
      SchedulerBinding.instance.addTimingsCallback(collect);
      try {
        await wait(const Duration(milliseconds: 500));
        final start = Timeline.now;
        await workload();
        var lastCount = timings.length;
        var lastChange = Timeline.now;
        while (Timeline.now - start < 5000000) {
          await wait(const Duration(milliseconds: 20));
          if (timings.length != lastCount) {
            lastCount = timings.length;
            lastChange = Timeline.now;
          } else if (Timeline.now - lastChange > 150000) {
            break;
          }
        }
        final end = Timeline.now;
        return frameStats(
          timings,
          start: start,
          end: end,
          refreshHz: refreshHz,
        );
      } finally {
        SchedulerBinding.instance.removeTimingsCallback(collect);
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
        for (var step = 0; step < 10; step++) {
          await gesture.moveBy(Offset(0, -distancePerDrag / 10));
          await wait(const Duration(milliseconds: 35));
        }
        await wait(const Duration(milliseconds: 80));
        await gesture.up();
        await wait(const Duration(milliseconds: 120));
      }
    }

    Future<Map<String, Object?>> profileScroll(Finder scrollable) async {
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scrollable, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      final before = position.pixels;
      final stats = await collectScrollFrames(
        () => dragDown(scrollable, drags: 3, distancePerDrag: 350),
      );
      return {
        ...stats,
        'requested_scroll_distance_dp': 1050,
        'actual_scroll_delta_dp': position.pixels - before,
        'max_scroll_extent_dp': position.maxScrollExtent,
        'gesture_cadence':
            '3 controlled drags; 350 dp each in 10 pointer moves at 35 ms intervals, 80 ms hold before release, 120 ms between drags',
      };
    }

    Future<void> scrollToTop(Finder scrollable) async {
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scrollable, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      position.jumpTo(position.minScrollExtent);
      await tester.pump();
      await wait(const Duration(milliseconds: 250));
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
    );

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
    );

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
      );
      sample.remove('action_end_monotonic_us');
      warmedTabs.add(sample);
    }
    results['warmed_demo_to_gallery'] = summarizeSamples(warmedTabs);

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
      );
      sample.remove('action_end_monotonic_us');
      warmedViews.add(sample);
    }
    results['warmed_gallery_views_payment_context'] = summarizeSamples(
      warmedViews,
    );

    final gallery = galleryList();
    await scrollToTop(gallery);
    results['gallery_views_scroll_first_reveal'] = await profileScroll(gallery);
    await scrollToTop(gallery);
    results['gallery_views_scroll_repeat'] = await profileScroll(gallery);
    results['gallery_views_scroll_components_on_path'] = [
      'PaymentContextView',
      'PaymentFullPageView',
      'PaymentFocusView',
      'PaymentSettingsView',
    ];

    await tapTab('Demo');
    app.updateSettings(const DemoSettings(locale: Locale('id'), textScale: 1));
    await settle(tester);

    Future<Map<String, Object?>> measureHistory() async {
      final sample = await measureAction(
        () => tester.tap(find.text('Transaksi')),
        destinationReady: () => find.byType(HistoryStep).evaluate().isNotEmpty,
      );
      final actionEnd = sample.remove('action_end_monotonic_us') as int;
      final deadline = Timeline.now + 2500000;
      while (app.coordinator.historyLoading && Timeline.now < deadline) {
        await wait(const Duration(milliseconds: 5));
      }
      if (app.coordinator.historyLoading) {
        throw TestFailure('Transaksi fixture did not finish loading');
      }
      sample['history_loaded_after_action_ms'] = ms(Timeline.now - actionEnd);
      sample['seeded_transaction_count'] = app.coordinator.history.length;
      return sample;
    }

    results['first_demo_to_transaksi'] = await measureHistory();
    await waitForHistoryBack(tester, app);
    final warmedHistory = <Map<String, Object?>>[];
    for (var i = 0; i < 3; i++) {
      final sample = await measureHistory();
      await waitForHistoryBack(tester, app);
      warmedHistory.add(sample);
    }
    results['warmed_demo_to_transaksi'] = summarizeSamples(warmedHistory);

    final historyPage = find.byType(HistoryStep);
    await measureHistory();
    await scrollToTop(historyPage);
    results['transaksi_scroll_first_reveal'] = await profileScroll(historyPage);
    await scrollToTop(historyPage);
    results['transaksi_scroll_repeat'] = await profileScroll(historyPage);
    results['transaksi_components_on_path'] = [
      'TransactionHistory summary/chart header',
      'TransactionListItem rows from the 14-row seeded host fixture',
    ];

    expect(tester.takeException(), isNull);
    binding.reportData = {'gallery_navigation': results};
  });
}

Future<void> waitForHistoryBack(WidgetTester tester, DemoAppState app) async {
  while (app.coordinator.historyLoading) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  await tester.tap(find.byType(BackButton));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
