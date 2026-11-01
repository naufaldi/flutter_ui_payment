import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:flutter_ui_payment_example/screens/flow_screen.dart';
import 'package:flutter_ui_payment_example/screens/steps/order_context.dart';
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

  // #80: at 200% the step title wraps to two lines in a taller bar instead
  // of ending in "Konfirmasi pe…". The test font's glyphs are an em wide,
  // much wider than San Francisco, so a 484 dp window gives a word the room
  // a 375 pt iPhone SE gives it on the device; at 1024 dp it fits one line.
  for (final (language, title, width, lines) in [
    ('id', 'Konfirmasi pembayaran', 484.0, 2),
    ('en', 'Confirm payment', 484.0, 2),
    ('id', 'Konfirmasi pembayaran', 1024.0, 1),
  ]) {
    testWidgets('authorize title is not clipped at ${width}dp, 2x, $language', (
      t,
    ) async {
      surface(t, Size(width, 800));
      final app = await launch(
        t,
        settings: DemoSettings(locale: Locale(language), textScale: 2),
      );
      final c = await runScenario(t, app, 'P06');
      await pumpUntil(t, () => c.quote != null && !c.quoting);
      c.reviewOrder();
      unawaited(c.confirm());
      await pumpUntil(t, () => c.step == FlowStep.authorize);
      await settle(t);
      final bar = find.byType(AppBar);
      final text = find.descendant(of: bar, matching: find.text(title));
      final paragraph = t.renderObject<RenderParagraph>(text);
      expect(paragraph.didExceedMaxLines, isFalse);
      // The whole title is laid out, broken only between words.
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: title.length),
      );
      expect({for (final b in boxes) b.top}, hasLength(lines));
      if (lines == 2) {
        final second = paragraph.getPositionForOffset(
          Offset(0, boxes.last.top + 1),
        );
        expect(title[second.offset - 1], ' ');
      }
      final rect = t.getRect(text);
      final barRect = t.getRect(bar);
      expect(barRect.top <= rect.top && rect.bottom <= barRect.bottom, isTrue);
      // The bar grows only when the title needs the second line.
      final toolbar = t.getRect(
        find.descendant(of: bar, matching: find.byType(NavigationToolbar)),
      );
      expect(toolbar.height, lines == 1 ? kToolbarHeight : greaterThan(80));
      expect(t.takeException(), isNull);
      await drain(t);
    });
  }

  // #84: the checkout bar takes the content's column. From 840 dp of
  // content the checkout shows the order context beside the form, capped at
  // 1040 dp, and the bar's column and its action's end edge follow; below
  // that both keep the 640 dp column. Widths are the flow screen's, not the
  // window's: from an 840 dp window the app's side rail takes its share.
  group('checkout bar column follows the content (#84)', () {
    Future<({double screen, Rect content, Rect column, Rect action})>
    checkoutAt(WidgetTester t, Size size) async {
      surface(t, size);
      final app = await launch(
        t,
        settings: const DemoSettings(locale: Locale('en')),
      );
      final c = await runScenario(t, app, 'H02');
      await pumpUntil(t, () => c.quote != null && !c.quoting);
      await settle(t);
      expect(c.step, FlowStep.checkout);
      // Two columns: the row that holds the order context. One column: the
      // method picker, which spans the column.
      final twoColumns = find.byType(OrderContext).evaluate().isNotEmpty;
      final content = t.getRect(
        twoColumns
            ? find
                  .ancestor(
                    of: find.byType(OrderContext),
                    matching: find.byType(Row),
                  )
                  .first
            : find.byType(PaymentMethodPicker),
      );
      return (
        screen: t.getSize(find.byType(FlowScreen)).width,
        content: content,
        // The bar's LayoutBuilder fills its capped column.
        column: t.getRect(
          find
              .descendant(
                of: find.byType(PaymentActionBar),
                matching: find.byType(LayoutBuilder),
              )
              .first,
        ),
        action: t.getRect(find.byKey(const Key('review-order'))),
      );
    }

    void expectShared(
      ({double screen, Rect content, Rect column, Rect action}) r,
    ) {
      expect(r.column.width, moreOrLessEquals(r.content.width, epsilon: 1));
      expect(r.column.left, moreOrLessEquals(r.content.left, epsilon: 1));
      // The action hugs at the end edge of the content (D59, #79).
      expect(r.action.right, moreOrLessEquals(r.content.right, epsilon: 1));
      expect(r.action.width, lessThan(r.content.width / 2));
    }

    // iPad landscape sizes, then either side of 840 dp of content: the test
    // font's rail is about 130 dp, so 1001 and 1003 straddle it.
    for (final (size, twoColumns) in [
      (const Size(1024, 768), true),
      (const Size(1194, 834), true),
      (const Size(1003, 834), true),
      (const Size(1001, 834), false),
      (const Size(871, 1000), false),
      (const Size(744, 1133), false),
    ]) {
      testWidgets('${size.width.toInt()}dp: the bar takes the content column', (
        t,
      ) async {
        final r = await checkoutAt(t, size);
        // Guard: the window lands on the intended side of the rule.
        expect(r.screen - 32 >= 840, twoColumns);
        expect(
          find.byType(OrderContext),
          twoColumns ? findsOneWidget : findsNothing,
        );
        final width = twoColumns
            ? math.min(r.screen - 32, 1040.0)
            : math.min(r.screen - 32, 640.0);
        expect(r.content.width, moreOrLessEquals(width, epsilon: 1));
        // Centred in the flow screen.
        final screenLeft = size.width - r.screen;
        expect(
          r.content.left - screenLeft,
          moreOrLessEquals(size.width - r.content.right, epsilon: 1),
        );
        expectShared(r);
        await drain(t);
      });
    }

    testWidgets('393dp phone: the action is full width', (t) async {
      final r = await checkoutAt(t, const Size(393, 852));
      expect(r.column.width, 393 - 32);
      expect(r.action.left, 16);
      expect(r.action.width, 393 - 32);
      expect(r.content.width, moreOrLessEquals(393 - 32, epsilon: 1));
      await drain(t);
    });
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
