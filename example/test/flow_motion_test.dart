import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/coordinator/demo_coordinator.dart';
import 'package:rakit_ui_example/main.dart';

import '../integration_test/support.dart';

Finder body(FlowStep step) => find.byKey(ValueKey('flow-view-${step.name}'));

/// The route that shows [step]'s screen.
ModalRoute<Object?> routeOf(WidgetTester tester, FlowStep step) =>
    ModalRoute.of(tester.element(body(step)))!;

/// Sends one Android predictive back event, as the engine does.
Future<void> backGesture(
  WidgetTester tester,
  String method, [
  double progress = 0,
]) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
  SystemChannels.backGesture.name,
  SystemChannels.backGesture.codec.encodeMethodCall(
    MethodCall(method, {
      'touchOffset': [0.0, 300.0],
      'progress': progress,
      'swipeEdge': 0,
    }),
  ),
  (_) {},
);

/// History → transaction detail, settled.
Future<DemoCoordinator> openDetail(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(locale: Locale('en')),
}) async {
  final app = await launch(tester, settings: settings);
  final c = await runScenario(tester, app, 'A01');
  unawaited(c.openDetail(c.history.first));
  await settle(tester);
  expect(c.step, FlowStep.transactionDetail);
  return c;
}

void main() {
  testWidgets(
    'on iOS, an edge swipe on transaction detail returns to history',
    (tester) async {
      final c = await openDetail(tester);
      expect(
        routeOf(tester, FlowStep.transactionDetail).popGestureEnabled,
        isTrue,
      );
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      // Halfway across, history is already showing under the detail.
      final gesture = await tester.startGesture(Offset(2, size.height / 2));
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(Offset(size.width / 2, 0));
      await tester.pump();
      expect(body(FlowStep.history), findsOneWidget);
      expect(c.step, FlowStep.transactionDetail);
      await gesture.moveBy(Offset(size.width / 4, 0));
      await gesture.up();
      await settle(tester);
      expect(c.step, FlowStep.history);
      expect(body(FlowStep.transactionDetail), findsNothing);
      expect(find.text('Transactions'), findsWidgets);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('on Android, predictive back on documents returns to identity', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K01');
    c.acceptConsent();
    await settle(tester);
    c.submitIdentity(Map.of(demoIdentity));
    await settle(tester);
    expect(c.step, FlowStep.kycDocuments);
    final documents = routeOf(tester, FlowStep.kycDocuments);
    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', 0.5);
    await tester.pump();
    // The preview shows identity behind documents before the person commits.
    expect(documents.popGestureInProgress, isTrue);
    expect(body(FlowStep.kycIdentity), findsOneWidget);
    expect(c.step, FlowStep.kycDocuments);
    await backGesture(tester, 'commitBackGesture');
    await settle(tester);
    expect(c.step, FlowStep.kycIdentity);
    expect(body(FlowStep.kycDocuments), findsNothing);
    expect(body(FlowStep.kycIdentity), findsOneWidget);
  });

  testWidgets('back is blocked while authorizing, then returns to review', (
    tester,
  ) async {
    final app = await launch(tester, latencyScale: 1);
    final c = await runScenario(tester, app, 'H02');
    await pumpUntil(tester, () => c.quote != null && !c.quoting);
    c.reviewOrder();
    await settle(tester);
    final payment = routeOf(tester, FlowStep.confirm);
    unawaited(c.confirm());
    await pumpUntil(tester, () => c.step == FlowStep.authorize);
    await settle(tester);
    // The payment steps switch in place on one route with no swipe back.
    expect(routeOf(tester, FlowStep.authorize), same(payment));
    expect(payment.popGestureEnabled, isFalse);
    unawaited(c.authorize());
    await tester.pump();
    expect(c.authPhase, AuthorizationPhase.inProgress);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(c.step, FlowStep.authorize);
    expect(c.authPhase, AuthorizationPhase.inProgress);
    await pumpUntil(tester, () => c.authPhase != AuthorizationPhase.inProgress);
    await settle(tester);
    // Approval submits and moves on; drain it before the test ends.
    await pumpUntil(tester, () => c.step == FlowStep.payment);
    await settle(tester);
  });

  testWidgets('back from confirm pops to checkout', (tester) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'H02');
    await pumpUntil(tester, () => c.quote != null && !c.quoting);
    c.reviewOrder();
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(c.step, FlowStep.checkout);
    expect(find.byKey(const ValueKey('flow-list-checkout')), findsOneWidget);
    await pumpUntil(tester, () => !c.quoting);
  });

  testWidgets('back on another tab leaves the flow where it is', (
    tester,
  ) async {
    final c = await openDetail(tester);
    final app = tester.state<DemoAppState>(find.byType(DemoApp));
    app.selectTab(1);
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(c.step, FlowStep.transactionDetail);
  });

  testWidgets('Done on the receipt leaves with the receipt still readable', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'P15');
    await pumpUntil(
      tester,
      () => c.attempt?.status == PaymentStatus.succeeded,
      reason: 'payment succeeded',
    );
    if (c.step != FlowStep.receipt) {
      unawaited(c.paymentAction(PaymentAction.viewReceipt));
    }
    await pumpUntil(tester, () => c.receipt != null, reason: 'receipt');
    await settle(tester);
    final transactionId = c.receipt!.transactionId;
    await tester.tap(find.byKey(const Key('receipt-done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // finish() has cleared the receipt; the leaving screen still shows it.
    expect(c.receipt, isNull);
    expect(c.step, FlowStep.overview);
    expect(find.textContaining(transactionId), findsWidgets);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('receipt-done')), findsNothing);
  });

  testWidgets('switching account on confirm leaves without an error', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'H02');
    await pumpUntil(tester, () => c.quote != null && !c.quoting);
    c.reviewOrder();
    await settle(tester);
    expect(c.step, FlowStep.confirm);
    unawaited(c.switchAccount('B'));
    await tester.pump();
    // The account's quote is cleared at once, not kept for the transition.
    expect(c.quote, isNull);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(c.step, FlowStep.overview);
    expect(body(FlowStep.confirm), findsNothing);
  });

  testWidgets('with reduced motion, detail opens and closes in one frame', (
    tester,
  ) async {
    final c = await openDetail(
      tester,
      settings: const DemoSettings(locale: Locale('en'), reduceMotion: true),
    );
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(c.step, FlowStep.history);
    expect(body(FlowStep.transactionDetail), findsNothing);
    unawaited(c.openDetail(c.history.first));
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(body(FlowStep.history), findsNothing);
    expect(body(FlowStep.transactionDetail), findsOneWidget);
    await settle(tester);
  });

  testWidgets('reduced motion turned on mid-push finishes next frame', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'A01');
    unawaited(c.openDetail(c.history.first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    app.updateSettings(app.settings.copyWith(reduceMotion: true));
    await tester.pump();
    await tester.pump();
    // The route transition is done; the detail's own content may still move.
    final route = routeOf(tester, FlowStep.transactionDetail);
    expect(route.animation!.status, AnimationStatus.completed);
    expect(body(FlowStep.history), findsNothing);
    expect(body(FlowStep.transactionDetail), findsOneWidget);
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
