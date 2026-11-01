import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/main.dart';
import '../integration_test/support.dart';

// D62: on the payment path the priority action pins to the bottom and the
// app's tab bar is hidden.

Future<void> drain(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 2));
}

void surface(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Finder primaries() => find.byWidgetPredicate(
  (w) => w is PaymentButton && w.variant == PaymentButtonVariant.primary,
);

/// Pinned: outside every scroll view, so it's on screen without scrolling.
bool pinned(WidgetTester t, Finder f) =>
    find.ancestor(of: f, matching: find.byType(Scrollable)).evaluate().isEmpty;

void expectPinnedPrimary(WidgetTester t, {double height = 852}) {
  final primary = primaries();
  expect(primary, findsOneWidget);
  expect(pinned(t, primary), isTrue);
  expect(primary.hitTestable(), findsOneWidget);
  expect(t.getRect(primary).bottom, greaterThan(height * 0.75));
}

void main() {
  testWidgets('tab bar: shown on the overview, hidden in the payment flow', (
    t,
  ) async {
    surface(t, const Size(393, 852));
    final app = await launch(t);
    var c = await runScenario(t, app, 'H01');
    expect(c.step, FlowStep.overview);
    expect(find.byType(NavigationBar), findsOneWidget);

    c = await runScenario(t, app, 'H02');
    await pumpUntil(t, () => c.quote != null && !c.quoting);
    expect(c.step, FlowStep.checkout);
    expect(find.byType(NavigationBar), findsNothing);
    // The bar holds only the action, so the total isn't repeated (#64).
    final review = find.byKey(const Key('review-order'));
    expect(pinned(t, review), isTrue);
    expect(
      find.descendant(
        of: find.byType(PaymentActionBar),
        matching: find.byType(AmountText),
      ),
      findsNothing,
    );

    c.reviewOrder();
    await settle(t);
    expect(c.step, FlowStep.confirm);
    expect(find.byType(NavigationBar), findsNothing);
    expectPinnedPrimary(t);

    // Back leaves the flow, and the tab bar returns.
    c.goHome();
    await settle(t);
    expect(find.byType(NavigationBar), findsOneWidget);
    await drain(t);
  });

  testWidgets('KYC steps pin their submit at 375x667, 2x (#64)', (t) async {
    surface(t, const Size(375, 667));
    final app = await launch(
      t,
      settings: const DemoSettings(locale: Locale('en'), textScale: 2),
    );
    var c = await runScenario(t, app, 'K01');
    if (c.step == FlowStep.kycIntro) {
      c.acceptConsent();
      await settle(t);
    }
    expect(c.step, FlowStep.kycIdentity);
    final go = find.byKey(const Key('identity-continue'));
    expectPinnedPrimary(t, height: 667);
    expect(find.text('Continue'), findsOneWidget);
    // The pinned Continue validates the form like the inline one did.
    await t.tap(go);
    await settle(t);
    expect(c.step, FlowStep.kycIdentity);
    expect(t.widget<PaymentButton>(go).busy, isFalse);

    c = await runScenario(t, app, 'K06');
    expect(c.step, FlowStep.kycReview);
    expectPinnedPrimary(t, height: 667);
    expect(find.byKey(const Key('submit-kyc')).hitTestable(), findsOneWidget);
    await drain(t);
  });

  testWidgets('a scenario that opens on documents has the details done', (
    t,
  ) async {
    surface(t, const Size(393, 852));
    final app = await launch(
      t,
      settings: const DemoSettings(locale: Locale('en')),
    );
    final c = await runScenario(t, app, 'K05');
    expect(c.step, FlowStep.kycDocuments);
    expect(c.identity, isNotEmpty);
    expect(find.text('Step 2 of 3: Documents'), findsOneWidget);
    await drain(t);
  });

  testWidgets('authorize: the primary sits in the pinned footer', (t) async {
    surface(t, const Size(393, 852));
    final app = await launch(t);
    final c = await runScenario(t, app, 'P06');
    await pumpUntil(t, () => c.quote != null && !c.quoting);
    c.reviewOrder();
    unawaited(c.confirm());
    await pumpUntil(t, () => c.step == FlowStep.authorize);
    await settle(t);
    expect(find.byType(NavigationBar), findsNothing);
    expectPinnedPrimary(t);
    // Back to review is the quiet action under it (#49-3).
    final back = find.widgetWithText(PaymentButton, 'Back to review');
    expect(t.widget<PaymentButton>(back).variant, PaymentButtonVariant.quiet);
    expect(pinned(t, back), isTrue);
    expect(t.getRect(back).top, greaterThan(t.getRect(primaries()).bottom));
    // The total being authorized scrolls with the content.
    expect(pinned(t, find.byType(AmountText).first), isFalse);
    await drain(t);
  });

  testWidgets('status: the quiet Done joins the pinned primary', (t) async {
    surface(t, const Size(393, 852));
    final app = await launch(t);
    final c = await runScenario(t, app, 'P15');
    await pumpUntil(t, () => c.attempt?.status == PaymentStatus.succeeded);
    await settle(t);
    expect(find.byType(NavigationBar), findsNothing);
    expectPinnedPrimary(t);
    final done = find.byKey(const Key('done'));
    expect(t.widget<PaymentButton>(done).variant, PaymentButtonVariant.quiet);
    expect(pinned(t, done), isTrue);
    await drain(t);
  });

  testWidgets('receipt: Selesai is the one primary, pinned', (t) async {
    surface(t, const Size(393, 852));
    final app = await launch(t, settings: const DemoSettings());
    final c = await runScenario(t, app, 'P15');
    await pumpUntil(t, () => c.attempt?.status == PaymentStatus.succeeded);
    unawaited(c.paymentAction(PaymentAction.viewReceipt));
    await pumpUntil(t, () => c.receipt != null);
    await settle(t);
    expect(find.byType(NavigationBar), findsNothing);
    expectPinnedPrimary(t);
    final done = find.byKey(const Key('receipt-done'));
    expect(t.widget<PaymentButton>(done).label, 'Selesai');
    expect(t.widget<PaymentButton>(done).variant, PaymentButtonVariant.primary);
    final details = find.byKey(const Key('receipt-details'));
    expect(
      t.widget<PaymentButton>(details).variant,
      PaymentButtonVariant.quiet,
    );
    expect(pinned(t, details), isTrue);
    await drain(t);
  });

  testWidgets('demo tools open from settings on a pinned step', (t) async {
    surface(t, const Size(393, 852));
    final app = await launch(t);
    final c = await runScenario(t, app, 'P15');
    await pumpUntil(t, () => c.attempt?.status == PaymentStatus.succeeded);
    await settle(t);
    expect(find.byKey(const Key('host-stats')), findsNothing);
    // At most two trailing app-bar actions (account, settings), so step
    // titles keep their width (P7a).
    final bar = find.byType(AppBar).first;
    expect(t.widget<AppBar>(bar).actions, hasLength(2));
    await t.tap(find.byKey(const Key('settings')));
    await settle(t);
    await t.tap(find.byKey(const Key('demo-tools')));
    await settle(t);
    expect(find.byKey(const Key('host-stats')), findsOneWidget);
    await t.tap(find.byKey(const Key('host-background')));
    await settle(t);
    expect(find.byKey(const Key('host-stats')), findsNothing);
    await drain(t);
  });
}
