import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment_example/adapters/fake_host.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:flutter_ui_payment_example/scenarios/catalog.dart';

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

/// A few frames for route transitions and layout.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
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
  final search = find.descendant(
    of: find.byType(PaymentSearchField<String>),
    matching: find.byType(EditableText),
  );
  await tester.ensureVisible(search);
  await tester.enterText(search, 'Jawa B');
  await settle(tester);
  await tapVisible(tester, find.text('Jawa Barat'));
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
}
