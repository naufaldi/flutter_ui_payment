import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';

import 'package:flutter_ui_payment_example/adapters/fake_host.dart';
import 'package:flutter_ui_payment_example/scenarios/scenario_config.dart';
import 'package:flutter_ui_payment_example/screens/flow_screen.dart';
import 'package:flutter_ui_payment_example/themes.dart';

import '../integration_test/support.dart';

Finder body(FlowStep step) => find.byKey(ValueKey('flow-view-${step.name}'));
Finder fadeOf(Finder child) =>
    find.ancestor(of: child, matching: find.byType(FadeTransition)).first;

void main() {
  testWidgets('scenario shortcut edits back then advances to review', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K06');
    final rest = tester.getTopLeft(body(FlowStep.kycReview));
    c.editDocuments();
    await tester.pump();
    expect(tester.getTopLeft(body(FlowStep.kycDocuments)).dy, rest.dy);
    await settle(tester);
    c.goToReview();
    await tester.pump();
    expect(tester.getTopLeft(body(FlowStep.kycReview)).dy, rest.dy + 8);
    await settle(tester);
  });
  testWidgets('forward detail starts eight dp below rest', (tester) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'A01');
    unawaited(c.openDetail(c.history.first));
    await tester.pump();
    await settle(tester);
    final rest = tester.getTopLeft(body(FlowStep.transactionDetail));
    c.closeDetail();
    await settle(tester);
    unawaited(c.openDetail(c.history.first));
    await tester.pump();
    expect(
      tester.getTopLeft(body(FlowStep.transactionDetail)).dy,
      closeTo(rest.dy + 8, 0.001),
    );
    await settle(tester);
  });
  testWidgets('back history starts at rest without rise', (tester) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'A01');
    final rest = tester.getTopLeft(body(FlowStep.history));
    unawaited(c.openDetail(c.history.first));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(
      tester.getTopLeft(body(FlowStep.history)).dy,
      closeTo(rest.dy, 0.001),
    );
    await settle(tester);
  });
  testWidgets('checkout bar fades with entering body and exits immediately', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P01');
    c.goHome();
    await settle(tester);
    unawaited(c.openCheckout());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final bar = find.byType(PaymentActionBar);
    final opacity = tester.widget<FadeTransition>(fadeOf(bar)).opacity.value;
    final step = find.byKey(const ValueKey('flow-list-checkout'));
    expect(opacity, greaterThan(0));
    expect(opacity, lessThan(1));
    expect(
      opacity,
      closeTo(tester.widget<FadeTransition>(fadeOf(step)).opacity.value, 0.01),
    );
    c.goHome();
    await tester.pump();
    expect(bar, findsNothing);
    await settle(tester);
  });
  for (final mode in ['host', 'ios', 'android']) {
    testWidgets('mid-transition reduced motion finishes next frame: $mode', (
      tester,
    ) async {
      final reduced = ValueNotifier(false);
      final host = DemoHost(const ScenarioConfig())..languageCode = 'en';
      final c = DemoCoordinator(host)..starting = false;
      addTearDown(c.dispose);
      addTearDown(host.dispose);
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(DemoBrand.ruangBayar, Brightness.light),
          localizationsDelegates: const [PaymentLocalizations.delegate],
          home: ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, value, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations:
                    value || MediaQuery.disableAnimationsOf(context),
              ),
              child: child!,
            ),
            child: FlowScreen(
              coordinator: c,
              scenarioLabel: '',
              onRestart: () {},
              onBackground: () {},
              onOpenSettings: (_) {},
            ),
          ),
        ),
      );
      unawaited(c.openHistory());
      await pumpUntil(tester, () => !c.historyLoading);
      await settle(tester);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      unawaited(c.openDetail(c.history.first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      if (mode == 'host') {
        reduced.value = true;
      } else {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(
              reduceMotion: mode == 'ios',
              disableAnimations: mode == 'android',
            );
      }
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(body(FlowStep.history), findsNothing);
      expect(body(FlowStep.transactionDetail), findsOneWidget);
    });
  }
  testWidgets('direction flip keeps leaving scroll state and blocks input', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'A01');
    unawaited(c.openDetail(c.history.first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final list = find
        .descendant(
          of: body(FlowStep.transactionDetail),
          matching: find.byType(Scrollable),
        )
        .first;
    final state = tester.state<ScrollableState>(list);
    state.position.jumpTo(20);
    final offset = state.position.pixels;
    c.closeDetail();
    await tester.pump();
    expect(tester.state(list), same(state));
    expect(state.position.pixels, offset);
    expect(
      find.ancestor(
        of: body(FlowStep.transactionDetail),
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      ),
      findsWidgets,
    );
    expect(
      find.ancestor(
        of: body(FlowStep.transactionDetail),
        matching: find.byWidgetPredicate(
          (w) => w is ExcludeSemantics && w.excluding,
        ),
      ),
      findsWidgets,
    );
    await settle(tester);
  });
  testWidgets('leave pending uses kit confirm and preserves attempt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P12');
    final attempt = c.attempt;
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.widgetWithText(PaymentButton, 'Stay'), findsOneWidget);
    expect(find.widgetWithText(PaymentButton, 'Leave'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await settle(tester);
    expect(c.step, FlowStep.payment);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.text('Leave'));
    await settle(tester);
    expect(c.step, FlowStep.overview);
    expect(c.attempt, same(attempt));
  });
}
