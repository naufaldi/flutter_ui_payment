import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/adapters/fake_host.dart';
import 'package:flutter_ui_payment_example/demo_strings.dart';
import 'package:flutter_ui_payment_example/scenarios/catalog.dart';
import 'package:flutter_ui_payment_example/scenarios/scenario_config.dart';
import 'package:flutter_ui_payment_example/screens/flow_screen.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// PRD §14 performance profile. Run in profile mode:
///   flutter drive --profile --driver=test_driver/integration_driver.dart \
///     --target=integration_test/perf_test.dart -d DEVICE_ID
///
/// Each workload repeats for a 30 s warm-up, then frame timings are
/// collected for a 30 s measured window. Build and raster p95 are reported
/// separately; the result is written to build/perf/summary.json.
///
/// `--dart-define=PERF_ONLY=checkout` runs only the checkout workload (plus
/// its short 100% text diagnostic) when re-measuring a checkout change.
const warmUp = Duration(seconds: 30);
const measured = Duration(seconds: 30);
const only = String.fromEnvironment('PERF_ONLY');

double percentile(List<double> values, double p) {
  if (values.isEmpty) return double.nan;
  final sorted = [...values]..sort();
  final index = ((p / 100) * (sorted.length - 1)).round();
  return sorted[index];
}

Map<String, Object> summarize(List<FrameTiming> frames) {
  double ms(Duration d) => d.inMicroseconds / 1000;
  final build = [for (final f in frames) ms(f.buildDuration)];
  final raster = [for (final f in frames) ms(f.rasterDuration)];
  double round(double v) => (v * 100).roundToDouble() / 100;
  return {
    'frames': frames.length,
    'build_p50_ms': round(percentile(build, 50)),
    'build_p95_ms': round(percentile(build, 95)),
    'build_max_ms': round(percentile(build, 100)),
    'raster_p50_ms': round(percentile(raster, 50)),
    'raster_p95_ms': round(percentile(raster, 95)),
    'raster_max_ms': round(percentile(raster, 100)),
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(Duration d) => Future<void>.delayed(d);

  /// Runs [step] repeatedly for [warmUp], then again while recording frames.
  Future<Map<String, Object>> profile(
    Future<void> Function() step, {
    Duration warm = warmUp,
    Duration window = measured,
  }) async {
    final warmEnd = DateTime.now().add(warm);
    while (DateTime.now().isBefore(warmEnd)) {
      await step();
    }
    final frames = <FrameTiming>[];
    void collect(List<FrameTiming> timings) => frames.addAll(timings);
    SchedulerBinding.instance.addTimingsCallback(collect);
    final end = DateTime.now().add(window);
    while (DateTime.now().isBefore(end)) {
      await step();
    }
    await wait(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    return summarize(frames);
  }

  testWidgets('profile checkout scroll, status updates, document cycles', (
    tester,
  ) async {
    final app = await launch(tester, latencyScale: 0.2);
    final results = <String, Object>{
      'platform': Platform.operatingSystem,
      'os': Platform.operatingSystemVersion,
      'refresh_hz': PlatformDispatcher.instance.views.first.display.refreshRate,
      'warm_up_s': warmUp.inSeconds,
      'measured_s': measured.inSeconds,
    };

    // Checkout: fling the list both ways and switch method, which re-quotes
    // and animates the selection and summary.
    var c = await runScenario(tester, app, 'X02');
    await pumpUntil(tester, () => c.quote != null && !c.quoting);
    final list = find.byType(Scrollable).first;
    var toggle = false;
    Future<void> checkoutStep() async {
      await tester.fling(list, const Offset(0, -500), 1800);
      await wait(const Duration(milliseconds: 700));
      await tester.fling(list, const Offset(0, 500), 1800);
      await wait(const Duration(milliseconds: 700));
      toggle = !toggle;
      await c.selectMethod(c.methods[toggle ? 1 : 0]);
      await wait(const Duration(milliseconds: 300));
    }

    results['checkout'] = await profile(checkoutStep);

    // Diagnostic, not a budget: the same screen and workload at 100% text,
    // to tell text-size cost apart from the environment's raster floor.
    app.updateSettings(app.settings.copyWith(textScale: () => 1.0));
    await settle(tester);
    results['checkout_text100_diagnostic'] = await profile(
      checkoutStep,
      warm: const Duration(seconds: 5),
      window: const Duration(seconds: 15),
    );

    if (only == 'checkout') {
      // Environment control (checkout-only runs), not a budget: the same fling pattern over a plain
      // Material list with no kit widgets, to see the emulator's own raster
      // floor for continuous scrolling.
      final control = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: control,
          home: Scaffold(
            body: ListView.builder(
              itemCount: 200,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text('Row $i'),
                subtitle: const Text('Plain Material row'),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      final plain = find.byType(Scrollable).first;
      results['plain_list_control'] = await profile(
        () async {
          await tester.fling(plain, const Offset(0, -500), 1800);
          await wait(const Duration(milliseconds: 700));
          await tester.fling(plain, const Offset(0, 500), 1800);
          await wait(const Duration(milliseconds: 1000));
        },
        warm: const Duration(seconds: 5),
        window: const Duration(seconds: 15),
      );
      binding.reportData = results;
      return;
    }

    // Status: a host-owned check alternates processing/pending, so the
    // status view swaps state on every refresh.
    final steps = [
      for (var i = 0; i < 2000; i++)
        ServerStep(i.isEven ? PaymentStatus.processing : PaymentStatus.pending),
    ];
    app.runScenario(
      Scenario(
        id: 'PERF',
        title: const Bi('Profile', 'Profil'),
        expect: const Bi('', ''),
        variants: [
          ScenarioVariant(
            label: const Bi('Status', 'Status'),
            config: ScenarioConfig(
              kycRequired: false,
              seedAttempt: true,
              script: steps,
            ),
          ),
        ],
      ),
      0,
    );
    await tester.pump();
    c = app.coordinator;
    await pumpUntil(tester, () => c.attempt?.status != null);
    results['status'] = await profile(() async {
      await c.refreshStatus();
      await wait(const Duration(milliseconds: 400));
    });

    // Documents: 10 cycles of choose → replace mid-upload → leave screen.
    c = await runScenario(tester, app, 'K05');
    final req = documentRequirements(const DemoStrings('en')).first;
    final rss = <int>[];
    for (var i = 0; i < 10; i++) {
      final first = c.uploadDocument(req, demoFixtures[0].file);
      await wait(const Duration(milliseconds: 100));
      await c.uploadDocument(req, demoFixtures[1].file);
      await first;
      c.goHome();
      await wait(const Duration(milliseconds: 300));
      c.editDocuments();
      await wait(const Duration(milliseconds: 300));
      rss.add(ProcessInfo.currentRss);
    }
    final ignored = c.host.log.value
        .where((e) => e.message.contains('Ignored finished upload'))
        .length;
    results['documents'] = {
      'cycles': 10,
      'slots_held': c.documents.length,
      'stale_uploads_ignored': ignored,
      'rss_mb': [for (final b in rss) (b / (1024 * 1024)).round()],
    };
    expect(c.documents.length, 2);
    expect(ignored, 10);

    binding.reportData = results;
  });
}
