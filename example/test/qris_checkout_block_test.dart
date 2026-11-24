import 'dart:async';

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

      Future<void> show(
        PaymentAttempt current, {
        String? codeAttemptId,
        String issuanceId = 'code-a',
        bool includeCode = true,
      }) async {
        await tester.pumpWidget(
          BlockDemoShell(
            title: 'QRIS',
            dark: true,
            onToggleDark: () {},
            body: (_) => QrisCheckoutBlock(
              attempt: current,
              amount: const Money.idr(152500),
              clock: () => now,
              code: includeCode
                  ? (
                      attemptId: codeAttemptId ?? attempt.attemptId,
                      issuanceId: issuanceId,
                      payee: 'Ruang Bayar Akademi',
                      image: const AssetImage('assets/qris/demo-code.webp'),
                      expiresAt: qrisDemoExpiry,
                    )
                  : null,
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

      now = qrisDemoExpiry.subtract(const Duration(seconds: 2));
      await show(pending.copyWith(observation: Observation.unavailable));
      await show(pending, includeCode: false);
      await show(pending);
      expect(code, findsNothing, reason: 'The same code was already expired');
      expect(find.text('Kode QR kedaluwarsa'), findsOneWidget);
      await show(pending, issuanceId: 'code-b');
      expect(
        code,
        findsOneWidget,
        reason: 'A new issuance with the same deadline can still be scanned',
      );
      await show(pending);
      expect(code, findsNothing, reason: 'Issuing a new code cannot revive A');

      await show(withStatus(PaymentStatus.expired, 2));
      expect(find.text('Pembayaran kedaluwarsa'), findsOneWidget);
      expect(find.text('Buat pembayaran baru'), findsNothing);
      expect(code, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final inFlight in [false, true]) {
    testWidgets(
      inFlight
          ? 'an old attempt’s in-flight check does not block a new check'
          : 'a press begun on one attempt cannot check the next attempt',
      (tester) async {
        final checks = <String>[];
        final firstCheck = Completer<void>();

        Future<void> show(String attemptId) => tester.pumpWidget(
          BlockDemoShell(
            title: 'QRIS',
            dark: false,
            onToggleDark: () {},
            body: (_) => QrisCheckoutBlock(
              attempt: PaymentAttempt(
                attemptId: attemptId,
                quoteId: 'quote',
                quoteRevision: 1,
                methodId: 'qris',
                submission: SubmissionState.outcomeUnknown,
              ),
              amount: const Money.idr(152500),
              clock: () => qrisDemoStart,
              onCheckStatus: (id) async {
                checks.add(id);
                if (id == 'first') await firstCheck.future;
              },
            ),
          ),
        );

        final check = find.text('Cek status');
        await show('first');
        await tester.pumpAndSettle();
        final press = await tester.startGesture(tester.getCenter(check));
        if (inFlight) {
          await press.up();
          await tester.pump();
        }
        await show('second');
        if (!inFlight) await press.up();
        expect(checks, inFlight ? ['first'] : isEmpty);

        expect(check.hitTestable(), findsOneWidget);
        await tester.tap(check);
        await tester.pump();
        firstCheck.complete();
        await tester.pumpAndSettle();
        expect(checks, [if (inFlight) 'first', 'second']);
      },
    );
  }

  testWidgets('hiding other actions preserves a host refund', (tester) async {
    final attempt = PaymentAttempt(
      attemptId: 'refunded-attempt',
      quoteId: 'quote',
      quoteRevision: 1,
      methodId: 'qris',
      submission: SubmissionState.accepted,
      snapshot: PaymentStatusSnapshot(
        attemptId: 'refunded-attempt',
        serverReference: 'provider-ref-9',
        status: PaymentStatus.succeeded,
        revision: 2,
        updatedAt: qrisDemoStart,
        allowedActions: const {PaymentAction.contactSupport},
        refund: const RefundInfo(
          status: RefundStatus.partial,
          amount: Money.idr(52500),
          safeReason: 'Item not available',
        ),
      ),
    );
    await tester.pumpWidget(
      BlockDemoShell(
        title: 'QRIS',
        dark: false,
        onToggleDark: () {},
        body: (_) => QrisCheckoutBlock(
          attempt: attempt,
          amount: const Money.idr(152500),
          clock: () => qrisDemoStart,
          onCheckStatus: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hubungi bantuan'), findsNothing);
    final reason = find.text('Item not available');
    expect(reason, findsOneWidget);
    await tester.ensureVisible(reason);
    expect(reason.hitTestable(), findsOneWidget);
    final refundAmount = find.text('Rp52.500');
    await tester.ensureVisible(refundAmount);
    expect(refundAmount.hitTestable(), findsOneWidget);
  });
}
