import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/checkout_block_demo.dart';

Finder get pay => find.textContaining(RegExp(r'^Bayar Rp'));
Finder get check => find.text('Cek status');
Finder get demoMenu => find.byTooltip('Menu demo');

/// The pay action is the only primary button in the pinned footer; its
/// label stays in the tree (faded) while the button is busy.
Finder get payButton =>
    find.ancestor(of: pay, matching: find.byType(FilledButton));

PaymentQuote quoteFor(String methodId, int total) => PaymentQuote(
  id: 'Q-$methodId',
  revision: 1,
  methodId: methodId,
  lines: const [QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000))],
  total: Money.idr(total),
  expiresAt: DateTime(2026, 11, 4, 10, 47),
);

Future<void> chooseLook(WidgetTester tester, String label) async {
  await tester.tap(demoMenu);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PopupMenuItem<int>, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'runnable block preserves one attempt through lost response to receipt',
    (tester) async {
      final host = CheckoutDemoHost(delay: Duration.zero);
      await tester.pumpWidget(CheckoutBlockDemo(host: host));
      await tester.pumpAndSettle();
      expect(find.text('Biaya layanan'), findsOneWidget);
      await tester.tap(pay);
      await tester.pumpAndSettle();
      expect(host.submittedIds, hasLength(1));
      expect(find.byType(PaymentReceipt), findsNothing);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(host.checkedIds, host.submittedIds);
      expect(host.submittedIds, hasLength(1));
      expect(find.byType(PaymentReceipt), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(pay, findsOneWidget);
    },
  );

  testWidgets(
    'offline check preserves pending and the next check never sends again',
    (tester) async {
      final host = CheckoutDemoHost(
        scenario: CheckoutDemoScenario.pendingOffline,
        delay: Duration.zero,
      );
      await tester.pumpWidget(CheckoutBlockDemo(host: host));
      await tester.pumpAndSettle();
      await tester.tap(pay);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentReceipt), findsNothing);
      expect(host.submittedIds, hasLength(1));
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(host.checkedIds, [
        host.submittedIds.single,
        host.submittedIds.single,
      ]);
      expect(find.byType(PaymentReceipt), findsOneWidget);
    },
  );

  testWidgets(
    '320dp/200% receipt retry retains success and a reachable action',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final host = CheckoutDemoHost(
        scenario: CheckoutDemoScenario.receiptRetry,
        delay: Duration.zero,
      );
      await tester.pumpWidget(CheckoutBlockDemo(host: host, initialDark: true));
      await tester.pumpAndSettle();
      await tester.tap(pay);
      await tester.pumpAndSettle();
      expect(find.text('Struk belum tersedia'), findsOneWidget);
      expect(find.byType(PaymentReceipt), findsNothing);
      final retry = find.text('Lihat struk');
      expect(retry.hitTestable(), findsOneWidget);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(host.receiptLoads, 2);
      expect(host.submittedIds, hasLength(1));
      expect(find.byType(PaymentReceipt), findsOneWidget);
      expect(find.text('Selesai').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wallet look: the method sheet requotes and Pay waits for the answer',
    (tester) async {
      final host = CheckoutDemoHost(delay: Duration.zero);
      final vaQuote = Completer<PaymentQuote>();
      await tester.pumpWidget(
        CheckoutBlockDemo(
          host: host,
          quoteFor: (methodId) => methodId == 'va'
              ? vaQuote.future
              : Future.value(quoteFor(methodId, 102500)),
        ),
      );
      await tester.pumpAndSettle();
      await chooseLook(tester, 'Dompet');
      expect(find.text('Pakai metode lain'), findsOneWidget);
      expect(find.textContaining('Rp350.000'), findsWidgets);
      await tester.tap(find.text('Pakai metode lain'));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentSheet), findsOneWidget);
      await tester.tap(find.text('Virtual account'));
      // The sheet closes while the quote is still in flight: pump fixed
      // frames because the busy pay spinner never lets the tree settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PaymentSheet), findsNothing);
      // The new price is still in flight, so the pinned action stays
      // disabled and busy instead of paying the old quote.
      expect(tester.widget<FilledButton>(payButton).onPressed, isNull);
      vaQuote.complete(quoteFor('va', 104000));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rp104.000'), findsWidgets);
      expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);
      await tester.tap(pay);
      await tester.pumpAndSettle();
      expect(host.submittedIds, hasLength(1));
      expect(host.sentOrder!.quote.total, const Money.idr(104000));
      expect(host.sentOrder!.selectedMethodId, 'va');
    },
  );

  testWidgets(
    'the newest quote request wins; a slower earlier answer is dropped',
    (tester) async {
      final host = CheckoutDemoHost(delay: Duration.zero);
      final answers = <String, Completer<PaymentQuote>>{};
      await tester.pumpWidget(
        CheckoutBlockDemo(
          host: host,
          quoteFor: (methodId) {
            final answer = Completer<PaymentQuote>();
            answers[methodId] = answer;
            return answer.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Virtual account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Virtual account'));
      await tester.pump();
      await tester.ensureVisible(find.text('Saldo Ruang Bayar'));
      await tester.pump();
      await tester.tap(find.text('Saldo Ruang Bayar'));
      await tester.pump();
      // The balance answer lands first and is the live request. Fixed
      // pumps, not pumpAndSettle: a pending quote keeps the pay spinner
      // animating until its answer arrives.
      answers['balance']!.complete(quoteFor('balance', 102500));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rp102.500'), findsWidgets);
      // The stale VA answer arrives last and must not replace it.
      answers['va']!.complete(quoteFor('va', 104000));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rp104.000'), findsNothing);
      expect(find.textContaining('Rp102.500'), findsWidgets);
      expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);
    },
  );

  testWidgets(
    'switching looks keeps the session, the attempt and the typed email',
    (tester) async {
      final host = CheckoutDemoHost(delay: Duration.zero);
      await tester.pumpWidget(CheckoutBlockDemo(host: host));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'tamu@demo.id');
      await tester.pumpAndSettle();
      await chooseLook(tester, 'Dompet');
      expect(find.text('tamu@demo.id'), findsOneWidget);
      await tester.tap(pay);
      await tester.pumpAndSettle();
      expect(host.submittedIds, hasLength(1));
      // The attempt survives both look switches; only the theme changes.
      await chooseLook(tester, 'Invoice');
      expect(check, findsOneWidget);
      await chooseLook(tester, 'Dompet');
      expect(check, findsOneWidget);
      expect(host.submittedIds, hasLength(1));
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.byType(PaymentReceipt), findsOneWidget);
      expect(find.textContaining('•••• 2190'), findsOneWidget);
    },
  );

  testWidgets('the demo reduced-motion switch reaches kit status motion', (
    tester,
  ) async {
    final host = CheckoutDemoHost(delay: Duration.zero);
    await tester.pumpWidget(CheckoutBlockDemo(host: host));
    await tester.pumpAndSettle();
    await tester.tap(demoMenu);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(PopupMenuItem<int>, 'Kurangi gerakan'),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PaymentFullPageView));
    expect(PaymentMotion.of(context).reduced, isTrue);
    await tester.tap(pay);
    await tester.pump();
    // The status handoff is already settled: nothing is still animating.
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpAndSettle();
    expect(check, findsOneWidget);
  });

  testWidgets(
    '320dp/200% wallet review keeps the pay action visible and reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final host = CheckoutDemoHost(delay: Duration.zero);
      await tester.pumpWidget(CheckoutBlockDemo(host: host));
      await tester.pumpAndSettle();
      await chooseLook(tester, 'Dompet');
      expect(pay.hitTestable(), findsOneWidget);
      expect(tester.getSize(payButton).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    },
  );
}
