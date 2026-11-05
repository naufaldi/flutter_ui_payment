import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/checkout_block_demo.dart';

Finder get pay => find.textContaining(RegExp(r'^Bayar Rp'));
Finder get check => find.text('Cek status');

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
}
