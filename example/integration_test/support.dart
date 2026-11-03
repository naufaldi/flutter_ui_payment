import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment_example/adapters/fake_host.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:flutter_ui_payment_example/scenarios/catalog.dart';
import 'package:integration_test/integration_test.dart';

import 'capture_slices.dart';

export 'capture_slices.dart';

Finder galleryList() => find.byWidgetPredicate(
  (widget) =>
      widget is ListView &&
      widget.key is PageStorageKey<String> &&
      (widget.key! as PageStorageKey<String>).value.startsWith('gallery-'),
);

/// Leaves room for the crop cap between the measured app and navigation bars.
Size catalogCaptureSize(WidgetTester tester, {double physicalWidth = 720}) {
  final view = tester.binding.renderViews.first;
  final dpr = view.flutterView.devicePixelRatio;
  final appBar = tester.getRect(find.byType(AppBar).first);
  final gallery = tester.getRect(galleryList());
  final top = (appBar.bottom * dpr).ceil() / dpr + 1 / dpr;
  final bottomInset = view.size.height - gallery.bottom;
  return Size(
    physicalWidth,
    ((top + catalogCaptureHeight + bottomInset) * dpr).ceilToDouble(),
  );
}

/// Renders in-app, avoiding the Android surface conversion handshake.
/// [crop] identifies a gallery specimen. Flow captures omit the status band.
///
/// A specimen taller than [catalogCaptureHeight] continues in more images
/// (D90): `<name>_part2`, `<name>_part3` and so on, each at most the cap and
/// overlapping the one before by [continuationOverlap]. The gallery scrolls
/// for each part and returns to where it was.
Future<void> capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name, {
  Finder? crop,
}) async {
  final view = tester.binding.renderViews.first;
  final dpr = view.flutterView.devicePixelRatio;
  final statusBand = name.contains('_catalog_') || name.contains('_kit_')
      ? 0.0
      : view.flutterView.padding.top / dpr;
  if (crop == null) {
    await _report(
      binding,
      tester,
      name,
      Rect.fromLTWH(
        0,
        statusBand,
        view.size.width,
        view.size.height - statusBand,
      ),
    );
    return;
  }
  final specimen = tester.getRect(crop);
  final appBar = tester.getRect(find.byType(AppBar).first);
  // Round inward past the app bar's painted edge, including fractional pixels.
  final edge = (appBar.bottom * dpr).ceil() / dpr + 1 / dpr;
  final top = math.max(edge, specimen.top - 16);
  double visibleBottom() =>
      math.min(view.size.height, tester.getRect(galleryList()).bottom);
  final requestedBottom = specimen.bottom + 16;
  final bottom = math.min(
    math.min(requestedBottom, top + catalogCaptureHeight),
    visibleBottom(),
  );
  if (requestedBottom > visibleBottom()) {
    expect(
      bottom - top,
      greaterThanOrEqualTo(catalogCaptureHeight),
      reason:
          'Specimen $name is truncated by the gallery viewport before '
          'the $catalogCaptureHeight dp cap: requested bottom '
          '$requestedBottom, visible bottom ${visibleBottom()}, crop height '
          '${bottom - top}. Increase the virtual view height.',
    );
  }
  expect(bottom, greaterThan(top), reason: 'Specimen must be visible: $name');
  final left = math.max(0.0, specimen.left - 16);
  final right = math.min(view.size.width, specimen.right + 16);
  final slices = captureSlices(requestedBottom - top);
  if (slices.length > 1) {
    debugPrint(
      'Specimen $name continues in ${slices.length} images '
      '(requested ${requestedBottom - top} dp, cap $catalogCaptureHeight dp).',
    );
  }
  // The crop's top, measured from the specimen's top, stays fixed while the
  // gallery scrolls under it.
  final origin = top - specimen.top;
  final position = tester
      .state<ScrollableState>(
        find
            .descendant(of: galleryList(), matching: find.byType(Scrollable))
            .first,
      )
      .position;
  final resting = position.pixels;
  try {
    for (final (index, slice) in slices.indexed) {
      if (index > 0) {
        position.jumpTo(
          (resting + slice.start).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
      final sliceTop = tester.getRect(crop).top + origin + slice.start;
      final sliceBottom = sliceTop + slice.height;
      const slack = 0.01;
      expect(
        sliceTop,
        greaterThanOrEqualTo(edge - slack),
        reason: 'Part ${index + 1} of $name starts under the app bar.',
      );
      expect(
        sliceBottom,
        lessThanOrEqualTo(visibleBottom() + slack),
        reason: 'Part ${index + 1} of $name is cut by the gallery viewport.',
      );
      await _report(
        binding,
        tester,
        continuationName(name, index),
        Rect.fromLTRB(
          left,
          math.max(edge, sliceTop),
          right,
          math.min(visibleBottom(), sliceBottom),
        ),
      );
    }
  } finally {
    if (position.pixels != resting) {
      position.jumpTo(resting);
      await tester.pump();
    }
  }
}

Future<void> _report(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
  Rect bounds,
) async {
  final view = tester.binding.renderViews.first;
  final dpr = view.flutterView.devicePixelRatio;
  final layer = view.debugLayer! as OffsetLayer;
  // RenderView's root layer already contains the device-pixel transform.
  debugPrint('Capture bounds $name: $bounds; view=${view.size}; dpr=$dpr');
  final image = await layer.toImage(
    Rect.fromLTRB(
      bounds.left * dpr,
      bounds.top * dpr,
      bounds.right * dpr,
      bounds.bottom * dpr,
    ),
    pixelRatio: 1,
  );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final report = binding.reportData ??= <String, dynamic>{};
    ((report['screenshots'] ??= <Object>[]) as List).add(<String, Object>{
      'screenshotName': name,
      'bytes': data!.buffer.asUint8List().toList(),
    });
  } finally {
    image.dispose();
  }
}

/// Boots the demo app in English with a shortened simulated latency.
Future<DemoAppState> launch(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(locale: Locale('en')),
  double latencyScale = 0.05,
}) async {
  DemoHost.latencyScale = latencyScale;
  await tester.pumpWidget(DemoApp(initialSettings: settings));
  await tester.pump();
  return tester.state<DemoAppState>(find.byType(DemoApp));
}

Scenario scenarioById(String id) => scenarios.firstWhere((s) => s.id == id);

/// Runs a catalog scenario and waits until its starting screen is ready.
Future<DemoCoordinator> runScenario(
  WidgetTester tester,
  DemoAppState app,
  String id, {
  int variant = 0,
}) async {
  app.runScenario(scenarioById(id), variant);
  await tester.pump();
  await pumpUntil(tester, () => !app.coordinator.starting);
  await settle(tester);
  return app.coordinator;
}

/// Pumps frames until [condition] holds. Works with fake time (flutter test)
/// and real time (device), unlike pumpAndSettle with spinners and timers.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  String? reason,
}) async {
  const step = Duration(milliseconds: 50);
  for (var waited = Duration.zero; !condition(); waited += step) {
    if (waited > timeout) {
      throw TestFailure('Timed out waiting for ${reason ?? 'condition'}');
    }
    await tester.pump(step);
  }
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) => pumpUntil(
  tester,
  () => finder.evaluate().isNotEmpty,
  timeout: timeout,
  reason: finder.describeMatch(Plurality.one),
);

/// A few frames for route transitions and layout. The flow's page transitions
/// take 450 ms on Android and 500 ms on iOS from the frame they start (D93).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Scrolls the flow list until [finder] is visible, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder.first);
  await settle(tester);
  await tester.tap(finder.first);
  await tester.pump();
}

Finder textOf(String text) => find.text(text);

/// Any button whose label starts with "Pay " (pay or pay-again style).
Finder payButtons() => find.byWidgetPredicate(
  (w) => w is Text && (w.data?.startsWith('Pay Rp') ?? false),
);

Future<void> fillIdentity(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Sari Wulandari (Demo)');
  await tester.enterText(fields.at(1), '3100000000001234');
  await tester.enterText(fields.at(2), '17/08/1995');
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
  await Scrollable.ensureVisible(
    tester.element(find.byType(PaymentSelect<String>)),
    alignment: 0.5,
  );
  await settle(tester);
  await tapVisible(
    tester,
    find
        .descendant(
          of: find.byType(PaymentSelect<String>),
          matching: find.byType(InkWell),
        )
        .first,
  );
  await tapVisible(tester, find.text('Employee'));
  // On a phone the province field is a trigger for the search sheet (D50);
  // at 600 dp and wider it is an inline field with a floating list.
  final province = find.byType(PaymentSearchField<String>);
  await tester.ensureVisible(province);
  await settle(tester);
  final inline = find.descendant(
    of: province,
    matching: find.byType(EditableText),
  );
  if (inline.evaluate().isNotEmpty) {
    await tester.enterText(inline, 'Jawa B');
    await settle(tester);
    await tapVisible(tester, find.text('Jawa Barat').last);
  } else {
    await tapVisible(
      tester,
      find.descendant(of: province, matching: find.byType(InkWell)).first,
    );
    final search = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(EditableText),
    );
    await settle(tester);
    await pumpUntilFound(tester, search);
    await tester.enterText(search, 'Jawa B');
    await settle(tester);
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Jawa Barat'),
      ),
    );
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
}
