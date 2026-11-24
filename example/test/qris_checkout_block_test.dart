import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/block_demo_shell.dart';
import 'package:rakit_ui_example/compositions/qris_checkout_block.dart';
import 'package:rakit_ui_example/qris_checkout_demo.dart';

import 'support/small_screen.dart';

void main() {
  testWidgets(
    'expiry removes the code without settling or replacing the attempt',
    (tester) async {
      useSmallScreenLargeText(tester);
      var now = qrisDemoExpiry.subtract(const Duration(seconds: 1));
      final checks = <String>[];
      const attempt = PaymentAttempt(
        attemptId: 'qr-attempt-2',
        quoteId: 'quote-1',
        quoteRevision: 3,
        methodId: 'qris',
        submission: SubmissionState.accepted,
      );
      PaymentAttempt withStatus(PaymentStatus status, int revision) => attempt
          .reconcile(
            PaymentStatusSnapshot(
              attemptId: attempt.attemptId,
              serverReference: 'provider-ref-9',
              status: status,
              revision: revision,
              updatedAt: now,
              allowedActions: const {
                PaymentAction.checkStatus,
                PaymentAction.startNewAttempt,
                PaymentAction.contactSupport,
              },
            ),
          )
          .attempt;

      Future<void> show(PaymentAttempt current, {String? codeAttemptId}) async {
        await tester.pumpWidget(
          BlockDemoShell(
            title: 'QRIS',
            dark: true,
            onToggleDark: () {},
            body: (_) => QrisCheckoutBlock(
              attempt: current,
              amount: const Money.idr(152500),
              clock: () => now,
              code: (
                attemptId: codeAttemptId ?? attempt.attemptId,
                payee: 'Ruang Bayar Akademi',
                image: const AssetImage('assets/qris/demo-code.webp'),
                expiresAt: qrisDemoExpiry,
              ),
              onCheckStatus: (id) async => checks.add(id),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      final pending = withStatus(PaymentStatus.pending, 1);
      final code = find.byType(PaymentImage);
      final check = find.text('Cek status');
      await show(pending, codeAttemptId: 'qr-attempt-1');
      expect(code, findsNothing);

      await show(pending);
      expect(code, findsOneWidget);
      expect(find.text('Ruang Bayar Akademi'), findsOneWidget);
      expect(find.textContaining('152.500'), findsOneWidget);

      now = qrisDemoExpiry;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(code, findsNothing);
      expect(find.text('Kode QR kedaluwarsa'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Pembayaran kedaluwarsa'), findsNothing);
      expect(checks, isEmpty);
      expect(check.hitTestable(), findsOneWidget);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(checks, [attempt.attemptId]);
      expect(find.text('Menunggu'), findsOneWidget);

      await show(withStatus(PaymentStatus.expired, 2));
      expect(find.text('Pembayaran kedaluwarsa'), findsOneWidget);
      expect(find.text('Buat pembayaran baru'), findsNothing);
      expect(code, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
