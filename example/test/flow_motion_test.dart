import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';

import 'package:flutter_ui_payment_example/adapters/fake_host.dart';
import 'package:flutter_ui_payment_example/scenarios/scenario_config.dart';
import 'package:flutter_ui_payment_example/screens/flow_screen.dart';
import 'package:flutter_ui_payment_example/themes.dart';

import 'package:flutter_ui_payment_example/screens/steps/kyc_onboarding_step.dart';

import '../integration_test/support.dart';

Finder body(FlowStep step) => find.byKey(ValueKey('flow-view-${step.name}'));
Finder fadeOf(Finder child) =>
    find.ancestor(of: child, matching: find.byType(FadeTransition)).first;

void main() {
  testWidgets('leaving identity keeps its content during documents entry', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K01');
    c.acceptConsent();
    await settle(tester);
    c.editDocuments();
    await tester.pump();
    // Rebuilding an outgoing form (for example its busy state) must keep
    // the entry's original step, while coordinator data stays live.
    tester
        .element(
          find.descendant(
            of: body(FlowStep.kycIdentity),
            matching: find.byType(KycOnboardingStep),
          ),
        )
        .markNeedsBuild();
    await tester.pump(const Duration(milliseconds: 75));
    final leaving = body(FlowStep.kycIdentity);
    expect(
      find.descendant(of: leaving, matching: find.byType(IdentityForm)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: body(FlowStep.kycDocuments),
        matching: find.text('ID card (KTP)'),
      ),
      findsWidgets,
    );
    expect(
      find.ancestor(
        of: leaving,
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      ),
      findsWidgets,
    );
    expect(
      find.ancestor(
        of: leaving,
        matching: find.byWidgetPredicate(
          (w) => w is ExcludeSemantics && w.excluding,
        ),
      ),
      findsWidgets,
    );
    await settle(tester);
  });
  for (final transition in [
    'identity-documents',
    'documents-identity',
    'detail-history',
  ]) {
    testWidgets('outgoing $transition fades in place on every frame', (
      tester,
    ) async {
      final app = await launch(tester);
      final detail = transition == 'detail-history';
      final forward = transition == 'identity-documents';
      final c = await runScenario(tester, app, detail ? 'A01' : 'K01');
      if (detail) {
        unawaited(c.openDetail(c.history.first));
      } else {
        c.acceptConsent();
      }
      await settle(tester);
      if (!detail && !forward) {
        c.editDocuments();
        await settle(tester);
      }
      final leaving = body(c.step);
      final rest = tester.getTopLeft(leaving);
      if (detail) {
        c.closeDetail();
      } else if (forward) {
        c.editDocuments();
      } else {
        c.editIdentity();
      }
      await tester.pump();
      expect(tester.getTopLeft(body(c.step)).dy, rest.dy + (forward ? 8 : 0));
      for (var frame = 0; frame < 10; frame++) {
        if (leaving.evaluate().isNotEmpty) {
          expect(
            tester.getTopLeft(leaving).dy,
            closeTo(rest.dy, 0.001),
            reason: '$transition frame $frame',
          );
          if (frame > 0) {
            expect(
              tester.widget<FadeTransition>(fadeOf(leaving)).opacity.value,
              lessThan(1),
            );
          }
        }
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(leaving, findsNothing);
      await settle(tester);
    });
  }

  testWidgets('status-first correction submits forward to status', (
    tester,
  ) async {
    final app = await launch(tester);
    final c = await runScenario(tester, app, 'K07', variant: 1);
    final rest = tester.getTopLeft(body(FlowStep.kycStatus));
    await c.kycAction(VerificationAction.fixDetails);
    await settle(tester);
    expect(c.step, FlowStep.kycDocuments);
    c.goToReview();
    await settle(tester);
    unawaited(c.submitKyc());
    await pumpUntil(tester, () => !c.kycSubmitting);
    expect(c.step, FlowStep.kycStatus);
    expect(tester.getTopLeft(body(FlowStep.kycStatus)).dy, rest.dy + 8);
    await settle(tester);
  });
  for (final visitedIntro in [false, true]) {
    testWidgets('status restart rises with visited intro: $visitedIntro', (
      tester,
    ) async {
      final app = await launch(tester);
      final c = await runScenario(tester, app, visitedIntro ? 'K01' : 'K08');
      final rest = tester.getTopLeft(body(c.step));
      if (visitedIntro) {
        c.acceptConsent();
        await settle(tester);
        c.editDocuments();
        await settle(tester);
        c.goToReview();
        await settle(tester);
        unawaited(c.submitKyc());
        await pumpUntil(tester, () => !c.kycSubmitting);
        await settle(tester);
        expect(c.step, FlowStep.kycStatus);
      }
      await c.kycAction(VerificationAction.start);
      await tester.pump();
      expect(c.step, FlowStep.kycIntro);
      expect(tester.getTopLeft(body(FlowStep.kycIntro)).dy, rest.dy + 8);
      await settle(tester);
    });
  }
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
