import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/compositions/host_checkout.dart';
import 'package:flutter_ui_payment_example/compositions/host_checkout_journey.dart';

final now = DateTime.utc(2026, 11, 4, 10);
CheckoutOrder order({String reference = 'ORDER-1'}) => CheckoutOrder(
  merchant: 'Demo Academy',
  reference: reference,
  quote: PaymentQuote(
    id: 'QUOTE-1',
    revision: 1,
    methodId: 'balance',
    lines: const [
      QuoteLine(label: 'Course', amount: Money.idr(100000)),
      QuoteLine(
        label: 'Service fee',
        amount: Money.idr(2500),
        kind: QuoteLineKind.fee,
      ),
    ],
    total: const Money.idr(102500),
    expiresAt: now.add(const Duration(minutes: 5)),
  ),
  methods: const [
    PaymentMethod(
      id: 'balance',
      label: 'Wallet',
      kind: PaymentMethodKind.balance,
    ),
  ],
  selectedMethodId: 'balance',
  balance: const Money.idr(350000),
  balanceState: BalanceState.sufficient,
);
PaymentStatusSnapshot snapshot(PaymentAttempt attempt, PaymentStatus status) =>
    PaymentStatusSnapshot(
      attemptId: attempt.attemptId,
      serverReference: 'TX-1',
      status: status,
      revision: status == PaymentStatus.succeeded ? 2 : 1,
      updatedAt: now,
      allowedActions: {
        status == PaymentStatus.succeeded
            ? PaymentAction.viewReceipt
            : PaymentAction.checkStatus,
      },
    );
PaymentReceiptData receipt() => PaymentReceiptData(
  transactionId: 'TX-1',
  merchantName: 'Demo Academy',
  paidAt: now,
  lines: order().quote.lines,
  total: order().quote.total,
  methodLabel: 'Wallet •••• 2190',
);
Widget journey({
  CheckoutOrder? data,
  DateTime Function()? clock,
  required Future<PaymentStatusSnapshot?> Function(
    PaymentAttempt,
    CheckoutOrder,
  )
  submit,
  Future<PaymentStatusSnapshot> Function(PaymentAttempt)? check,
  Future<PaymentReceiptData> Function(PaymentAttempt)? load,
  VoidCallback? done,
}) => HostCheckoutJourney(
  order: data ?? order(),
  clock: clock ?? () => now,
  newAttemptId: () => 'ATT-1',
  onSelectMethod: (_) {},
  onReceiptEmailChanged: (_) {},
  onSubmit: submit,
  onCheckStatus:
      check ?? (attempt) async => snapshot(attempt, PaymentStatus.succeeded),
  onLoadReceipt: load ?? (_) async => receipt(),
  onOtherAction: (_, _) {},
  onDone: done ?? () {},
  onShare: (_) async => ShareOutcome.dismissed,
  onCopy: (_) async => true,
);
Widget frame(Widget child, {double scale = 1}) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3355AA));
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      extensions: [PaymentTheme.fromColorScheme(scheme)],
    ),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

Finder get pay => find.textContaining(RegExp(r'^Pay Rp'));

void main() {
  testWidgets('320 dp/200%: review -> lost response -> check the same attempt '
      'once -> matching receipt -> Done', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pending = Completer<PaymentStatusSnapshot?>();
    final submitted = <PaymentAttempt>[];
    final checked = <String>[];
    var dones = 0;
    await tester.pumpWidget(
      frame(
        journey(
          submit: (attempt, data) {
            submitted.add(attempt);
            return pending.future;
          },
          check: (attempt) async {
            checked.add(attempt.attemptId);
            return snapshot(attempt, PaymentStatus.succeeded);
          },
          done: () => dones++,
        ),
        scale: 2,
      ),
    );
    expect(find.text('Service fee'), findsOneWidget);
    await tester.ensureVisible(pay);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(pay);
    await tester.pump();
    expect(submitted, hasLength(1));
    // While sending, the only status action is busy and cannot reconcile yet.
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(checked, isEmpty);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(
      find.text(PaymentLocalizations('en').statusUnknownLead),
      findsOneWidget,
    );
    expect(pay, findsNothing);
    await tester.tap(find.text('Check status'));
    await tester.pumpAndSettle();
    expect(checked, ['ATT-1']);
    expect(submitted, hasLength(1));
    expect(find.byType(PaymentReceipt), findsOneWidget);
    await tester.tap(find.text('Done'));
    expect(dones, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline refresh keeps pending; a failed receipt load can retry '
      'without paying again', (tester) async {
    var checks = 0;
    var loads = 0;
    await tester.pumpWidget(
      frame(
        journey(
          submit: (attempt, _) async =>
              snapshot(attempt, PaymentStatus.pending),
          check: (attempt) async {
            if (++checks == 1) throw StateError('Synthetic offline');
            return snapshot(attempt, PaymentStatus.succeeded);
          },
          load: (_) async {
            if (++loads == 1) throw StateError('Synthetic receipt failure');
            return receipt();
          },
        ),
      ),
    );
    await tester.tap(pay);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check status'));
    await tester.pumpAndSettle();
    final status = tester.widget<PaymentStatusView>(
      find.byType(PaymentStatusView),
    );
    expect(status.attempt.status, PaymentStatus.pending);
    expect(status.attempt.observation, Observation.unavailable);
    await tester.tap(find.text('Check status'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt unavailable'), findsOneWidget);
    expect(find.byType(PaymentReceipt), findsNothing);
    await tester.tap(
      find.text(
        PaymentLocalizations(
          'en',
        ).paymentActionLabel(PaymentAction.viewReceipt),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaymentReceipt), findsOneWidget);
    expect(loads, 2);
    expect(pay, findsNothing);
  });

  testWidgets(
    'a response from the previous host order cannot replace a new review',
    (tester) async {
      final pending = Completer<PaymentStatusSnapshot?>();
      PaymentAttempt? sent;
      final child = journey(
        submit: (attempt, _) {
          sent = attempt;
          return pending.future;
        },
      );
      await tester.pumpWidget(frame(child));
      await tester.tap(pay);
      await tester.pump();
      await tester.pumpWidget(
        frame(
          journey(
            data: order(reference: 'ORDER-2'),
            submit: (_, _) async => null,
          ),
        ),
      );
      pending.complete(snapshot(sent!, PaymentStatus.succeeded));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentStatusView), findsNothing);
      expect(find.byType(PaymentReceipt), findsNothing);
      expect(
        find.textContaining('ORDER-2', findRichText: true),
        findsOneWidget,
      );
      expect(pay, findsOneWidget);
    },
  );

  testWidgets(
    'expiry is checked again before submission and explains why pay stopped',
    (tester) async {
      var clock = now;
      var submits = 0;
      await tester.pumpWidget(
        frame(
          journey(
            clock: () => clock,
            submit: (_, _) async {
              submits++;
              return null;
            },
          ),
        ),
      );
      clock = now.add(const Duration(minutes: 6));
      await tester.tap(pay);
      await tester.pumpAndSettle();
      expect(submits, 0);
      expect(find.text('Payment not ready'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    },
  );
}
