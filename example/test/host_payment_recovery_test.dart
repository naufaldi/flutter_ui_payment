import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/compositions/host_checkout.dart';
import 'package:flutter_ui_payment_example/compositions/host_payment_recovery.dart';

const unknown = PaymentAttempt(
  attemptId: 'attempt-restored',
  quoteId: 'quote-original',
  quoteRevision: 1,
  methodId: 'wallet',
  submission: SubmissionState.outcomeUnknown,
);
final updated = DateTime.utc(2026, 11, 3, 10);
PaymentStatusSnapshot snapshot(PaymentStatus status) => PaymentStatusSnapshot(
  attemptId: unknown.attemptId,
  serverReference: 'TX-123',
  status: status,
  revision: 1,
  updatedAt: updated,
  allowedActions: status == PaymentStatus.succeeded
      ? {PaymentAction.viewReceipt}
      : {PaymentAction.checkStatus},
);
PaymentReceiptData receipt({String id = 'TX-123'}) => PaymentReceiptData(
  transactionId: id,
  merchantName: 'Demo Academy',
  paidAt: updated,
  lines: const [QuoteLine(label: 'Course', amount: Money.idr(100000))],
  total: const Money.idr(100000),
  methodLabel: 'Wallet •••• 2190',
);

Widget host(Widget child, {double scale = 1}) {
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
        child: Scaffold(body: ProductLooks(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('unknown recovery checks the same attempt once, then shows '
      'only the host-confirmed receipt', (tester) async {
    final state = ValueNotifier(unknown);
    addTearDown(state.dispose);
    final pending = Completer<void>();
    final calls = <String>[];
    await tester.pumpWidget(
      host(
        ValueListenableBuilder(
          valueListenable: state,
          builder: (context, attempt, _) => HostPaymentRecovery(
            attempt: attempt,
            amount: const Money.idr(100000),
            receipt: receipt(), // Early data must never imply payment success.
            onAction: (id, action) {
              calls.add('$id:${action.name}');
              return pending.future;
            },
            onDone: () {},
            onShare: (_) async => ShareOutcome.dismissed,
            onCopy: (_) async => true,
          ),
        ),
      ),
    );
    expect(find.byType(PaymentReceipt), findsNothing);
    expect(
      find.text(PaymentLocalizations('en').statusUnknownLead),
      findsOneWidget,
    );
    final check = find.text('Check status');
    await tester.tap(check);
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(calls, ['attempt-restored:checkStatus']);
    pending.complete();
    state.value = unknown.reconcile(snapshot(PaymentStatus.succeeded)).attempt;
    await tester.pumpAndSettle();
    expect(find.byType(PaymentReceipt), findsOneWidget);
    expect(find.text('TX-123'), findsOneWidget);
  });

  testWidgets('failed refresh retains pending at 320 dp and 200% text; '
      'the status action remains reachable', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var checks = 0;
    final pending = unknown.reconcile(snapshot(PaymentStatus.pending)).attempt;
    await tester.pumpWidget(
      host(
        HostPaymentRecovery(
          attempt: pending.copyWith(
            observation: Observation.unavailable,
            lastCheckedAt: updated,
          ),
          amount: const Money.idr(100000),
          receipt: receipt(),
          onAction: (id, action) {
            if (action == PaymentAction.checkStatus) checks++;
          },
          onDone: () {},
          onShare: (_) async => ShareOutcome.dismissed,
          onCopy: (_) async => true,
        ),
        scale: 2,
      ),
    );
    expect(find.byType(PaymentReceipt), findsNothing);
    final view = tester.widget<PaymentStatusView>(
      find.byType(PaymentStatusView),
    );
    expect(view.attempt.status, PaymentStatus.pending);
    await tester.ensureVisible(find.text('Check status'));
    expect(
      tester.getSize(find.byType(FilledButton).first).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Check status'));
    await tester.pump();
    expect(checks, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a receipt from another transaction stays hidden after success', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        HostPaymentRecovery(
          attempt: unknown.reconcile(snapshot(PaymentStatus.succeeded)).attempt,
          amount: const Money.idr(100000),
          receipt: receipt(id: 'TX-OTHER'),
          onAction: (_, _) {},
          onDone: () {},
          onShare: (_) async => ShareOutcome.dismissed,
          onCopy: (_) async => true,
        ),
      ),
    );
    expect(find.byType(PaymentReceipt), findsNothing);
    expect(find.byType(PaymentStatusView), findsOneWidget);
    expect(find.text('TX-OTHER'), findsNothing);
  });
}
