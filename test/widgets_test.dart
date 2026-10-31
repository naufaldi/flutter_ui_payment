import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

Widget host(
  Widget child, {
  String language = 'en',
  double textScale = 1,
  ThemeData? theme,
  Size size = const Size(390, 844),
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
      theme: theme,
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        PaymentLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

final _quote = PaymentQuote(
  id: 'Q-1',
  revision: 1,
  lines: const [
    QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
    QuoteLine(
      label: 'Service fee',
      amount: Money.idr(2500),
      kind: QuoteLineKind.fee,
    ),
  ],
  total: const Money.idr(102500),
  expiresAt: DateTime.utc(2030),
  methodId: 'balance',
);

final _changedQuote = PaymentQuote(
  id: 'Q-1',
  revision: 2,
  lines: const [
    QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
    QuoteLine(
      label: 'Service fee',
      amount: Money.idr(3500),
      kind: QuoteLineKind.fee,
    ),
  ],
  total: const Money.idr(103500),
  expiresAt: DateTime.utc(2030),
  methodId: 'balance',
);

const _balance = PaymentMethod(
  id: 'balance',
  label: 'Ruang Bayar balance',
  kind: PaymentMethodKind.balance,
  detail: 'Balance Rp350.000',
);

PaymentAttempt _attempt({
  SubmissionState submission = SubmissionState.accepted,
  PaymentStatus? status,
  Set<PaymentAction> actions = const {},
  Observation observation = Observation.fresh,
  RefundInfo refund = const RefundInfo(status: RefundStatus.none),
}) => PaymentAttempt(
  attemptId: 'att-1',
  quoteId: 'Q-1',
  quoteRevision: 1,
  methodId: 'balance',
  submission: submission,
  observation: observation,
  lastCheckedAt: DateTime.utc(2026, 10, 30, 9),
  snapshot: status == null
      ? null
      : PaymentStatusSnapshot(
          attemptId: 'att-1',
          serverReference: 'TRX-004071',
          status: status,
          revision: 2,
          updatedAt: DateTime.utc(2026, 10, 30, 9),
          allowedActions: actions,
          refund: refund,
        ),
);

void main() {
  testWidgets('PaymentButton runs one callback at a time', (tester) async {
    final gate = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentButton(
          label: 'Pay',
          onPressed: () {
            calls++;
            return gate.future;
          },
        ),
      ),
    );
    await tester.tap(find.text('Pay'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay'));
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('changed quote needs explicit reapproval before paying', (
    tester,
  ) async {
    var confirms = 0;
    Future<void> confirm() async => confirms++;
    await tester.pumpWidget(
      host(
        PaymentConfirmation(
          quote: _changedQuote,
          previousQuote: _quote,
          method: _balance,
          onConfirm: confirm,
        ),
      ),
    );
    expect(find.text('The total has changed'), findsOneWidget);
    await tester.tap(find.text('Pay Rp103,500'), warnIfMissed: false);
    await tester.pump();
    expect(confirms, 0);

    await tester.tap(find.byType(PaymentCheckbox));
    await tester.pump();
    await tester.tap(find.text('Pay Rp103,500'));
    await tester.pump();
    expect(confirms, 1);
  });

  testWidgets('unknown outcome offers only Check status, never pay again', (
    tester,
  ) async {
    final actions = <PaymentAction>[];
    await tester.pumpWidget(
      host(
        PaymentStatusView(
          attempt: _attempt(submission: SubmissionState.outcomeUnknown),
          amount: const Money.idr(102500),
          onAction: actions.add,
        ),
      ),
    );
    expect(find.text('Result not confirmed yet'), findsOneWidget);
    expect(find.byType(PaymentButton), findsOneWidget);
    expect(find.text('Check status'), findsOneWidget);
    await tester.tap(find.text('Check status'));
    expect(actions, [PaymentAction.checkStatus]);
  });

  testWidgets('unknown outcome leads with "don\'t pay again" and has no '
      'fake update time', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentStatusView(
          attempt: _attempt(submission: SubmissionState.outcomeUnknown),
          amount: const Money.idr(102500),
          onAction: (_) {},
        ),
      ),
    );
    expect(find.text('Don’t pay again.'), findsOneWidget);
    // Without a host snapshot there is no update time to show; a status
    // phrase must not stand in for one.
    expect(find.text('Last updated'), findsNothing);
    expect(find.text('Not confirmed yet'), findsNothing);
    final band = tester.widget<StatusBand>(find.byType(StatusBand));
    expect(band.hatched, isTrue);
  });

  testWidgets('offline refresh keeps last-known pending, not failed', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PaymentStatusView(
          attempt: _attempt(
            status: PaymentStatus.pending,
            actions: {PaymentAction.checkStatus},
            observation: Observation.unavailable,
          ),
          onAction: (_) {},
        ),
      ),
    );
    expect(find.text('Pending'), findsOneWidget);
    expect(find.textContaining('Failed'), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('refund is shown beside the original success', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentStatusView(
          attempt: _attempt(
            status: PaymentStatus.succeeded,
            actions: {PaymentAction.viewReceipt},
            refund: const RefundInfo(
              status: RefundStatus.partial,
              amount: Money.idr(250000),
            ),
          ),
          amount: const Money.idr(102500),
          onAction: (_) {},
        ),
      ),
    );
    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.text('Refund'), findsOneWidget);
    // Above the paid amount: treated as invalid host data, not rendered.
    expect(find.text('Rp250,000'), findsNothing);
  });

  testWidgets('consent starts unchecked and gates Continue', (tester) async {
    var continued = 0;
    await tester.pumpWidget(
      host(
        VerificationIntro(
          requirements: const [
            DataRequirement(title: 'ID card', purpose: 'To match your name'),
          ],
          onContinue: () => continued++,
        ),
      ),
    );
    final checkbox = tester.widget<PaymentCheckbox>(
      find.byType(PaymentCheckbox),
    );
    expect(checkbox.value, isFalse);
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    expect(continued, 0);
    await tester.tap(find.byType(PaymentCheckbox));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    expect(continued, 1);
  });

  testWidgets('identity form shows field errors and accepts any script', (
    tester,
  ) async {
    Map<String, String>? submitted;
    final fields = [
      IdentityFieldSpec(
        key: 'name',
        label: 'Full name',
        validator: (v) => v.isEmpty ? 'Enter your name' : null,
      ),
      IdentityFieldSpec(
        key: 'nik',
        label: 'ID number',
        validator: (v) =>
            RegExp(r'^\d{16}$').hasMatch(v) ? null : 'Use 16 digits',
      ),
    ];
    await tester.pumpWidget(
      host(IdentityForm(fields: fields, onSubmit: (v) => submitted = v)),
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Use 16 digits'), findsOneWidget);
    expect(submitted, isNull);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Đặng Thị Ngọc Ánh',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '3100000000001234',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(submitted, {'name': 'Đặng Thị Ngọc Ánh', 'nik': '3100000000001234'});
  });

  testWidgets('unavailable methods show the reason and cannot be chosen', (
    tester,
  ) async {
    final chosen = <String>[];
    await tester.pumpWidget(
      host(
        PaymentMethodPicker(
          methods: const [
            _balance,
            PaymentMethod(
              id: 'card',
              label: 'Card •••• 4242',
              kind: PaymentMethodKind.card,
              unavailableReason: 'Not accepted for this purchase',
            ),
          ],
          selectedId: 'card',
          onChanged: (m) => chosen.add(m.id),
        ),
      ),
    );
    expect(
      find.text('Unavailable: Not accepted for this purchase'),
      findsOneWidget,
    );
    await tester.tap(find.text('Card •••• 4242'));
    expect(chosen, isEmpty);
    // A stale selection of an unavailable method renders as no selection.
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    await tester.tap(find.text('Ruang Bayar balance'));
    expect(chosen, ['balance']);
  });

  testWidgets('amount input rejects ambiguous paste and out-of-limit values', (
    tester,
  ) async {
    final results = <AmountParseResult>[];
    await tester.pumpWidget(
      host(
        PaymentCurrencyField(
          currency: 'IDR',
          minimum: const Money.idr(10000),
          maximum: const Money.idr(2000000),
          onChanged: results.add,
        ),
        language: 'id',
      ),
    );
    await tester.enterText(find.byType(TextField), '100,000');
    expect(results.last.issue, AmountIssue.ambiguous);
    await tester.enterText(find.byType(TextField), 'Rp 5.000');
    expect(results.last.issue, AmountIssue.belowMinimum);
    await tester.enterText(find.byType(TextField), '-50.000');
    expect(results.last.issue, AmountIssue.negative);
    await tester.enterText(find.byType(TextField), 'Rp 150.000');
    expect(results.last.money, const Money.idr(150000));
  });

  testWidgets('cancel and failure of the challenge read differently', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        AuthorizationPrompt(
          phase: AuthorizationPhase.canceled,
          onStart: () {},
          onBackToReview: () {},
        ),
      ),
    );
    final canceled = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .join('|');
    await tester.pumpWidget(
      host(
        AuthorizationPrompt(
          phase: AuthorizationPhase.failed,
          onStart: () {},
          onBackToReview: () {},
        ),
      ),
    );
    final failed = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .join('|');
    expect(canceled, isNot(failed));
    expect(find.text('Back to review'), findsOneWidget);
    expect(find.textContaining('successful'), findsNothing);
  });

  testWidgets('elapsed instructions stop at zero and ask the host', (
    tester,
  ) async {
    var elapsed = 0;
    final now = DateTime.utc(2026, 10, 30, 10);
    await tester.pumpWidget(
      host(
        PaymentInstructions(
          instructions: VirtualAccountInstructions(
            providerLabel: 'Bank Contoh',
            accountNumber: '8808 0012 3456 7890',
            amount: const Money.idr(104000),
            expiresAt: now.subtract(const Duration(minutes: 1)),
          ),
          clock: () => now,
          onElapsed: () => elapsed++,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Payment time has ended'), findsOneWidget);
    expect(elapsed, 1);
  });

  testWidgets('a failed share keeps the receipt and explains it', (
    tester,
  ) async {
    ReceiptShareData? shared;
    await tester.pumpWidget(
      host(
        PaymentReceipt(
          data: PaymentReceiptData(
            transactionId: 'TRX-004071',
            merchantName: 'Ruang Bayar Akademi',
            paidAt: DateTime.utc(2026, 10, 30, 9),
            lines: _quote.lines,
            total: _quote.total,
            methodLabel: 'Saldo •••• 2190',
          ),
          onShare: (data) async {
            shared = data;
            return ShareOutcome.failed;
          },
        ),
      ),
    );
    await tester.tap(find.text('Share receipt'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Couldn’t share'), findsOneWidget);
    expect(find.text('TRX-004071'), findsOneWidget);
    expect(shared!.fields.values, isNot(contains('Paket Belajar')));
  });

  testWidgets('host theme extension is applied without forking', (
    tester,
  ) async {
    const violet = Color(0xFF4338CA);
    final theme = ThemeData(
      extensions: [
        PaymentTheme.fromColorScheme(
          ColorScheme.fromSeed(seedColor: violet),
        ).copyWith(accent: violet, radius: 4),
      ],
    );
    await tester.pumpWidget(
      host(
        PaymentButton(label: 'Pay', onPressed: () {}),
        theme: theme,
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style!.backgroundColor!.resolve({}), violet);
  });

  testWidgets('PrivacyMask hides content from screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const PrivacyMask(obscured: true, child: Text('3100000000001234'))),
    );
    expect(find.bySemanticsLabel('3100000000001234'), findsNothing);
    expect(find.bySemanticsLabel('Content hidden'), findsOneWidget);
    semantics.dispose();
  });

  group('VA pending status with instructions', () {
    final now = DateTime.utc(2026, 10, 30, 10);
    final va = VirtualAccountInstructions(
      providerLabel: 'Bank Contoh',
      accountNumber: '8808 0012 3456 7890',
      amount: const Money.idr(104000),
      expiresAt: now.add(const Duration(hours: 1)),
      steps: const ['Open your banking app', 'Choose virtual account'],
    );

    // The countdown ticks every second, so these pump fixed frames instead
    // of settling.
    Future<void> pumpVa(WidgetTester tester, {double textScale = 1}) async {
      tester.view.physicalSize = const Size(720, 1248);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          PaymentStatusView(
            attempt: _attempt(
              status: PaymentStatus.pending,
              actions: {PaymentAction.checkStatus},
            ),
            amount: const Money.idr(104000),
            onAction: (_) {},
            instructions: PaymentInstructions(
              instructions: va,
              clock: () => now,
              onCopyNumber: (_) async => true,
            ),
          ),
          textScale: textScale,
          size: const Size(360, 624),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    final vaNumber = find.byType(SelectableText);

    testWidgets('shows one display amount', (tester) async {
      await pumpVa(tester);
      final display = find.byWidgetPredicate(
        (w) => w is Text && w.style?.fontSize == 32,
      );
      expect(
        find.ancestor(of: display, matching: find.byType(AmountText)),
        findsOneWidget,
      );
    });

    testWidgets('instructions come before Check status at 100%', (
      tester,
    ) async {
      await pumpVa(tester);
      expect(
        tester.getTopLeft(find.text('Check status')).dy,
        greaterThan(tester.getTopLeft(vaNumber).dy),
      );
    });

    testWidgets('Check status stays on the first screen at 200%', (
      tester,
    ) async {
      await pumpVa(tester, textScale: 2);
      expect(
        tester.getTopLeft(find.text('Check status')).dy,
        lessThan(tester.getTopLeft(vaNumber).dy),
      );
      expect(tester.getBottomLeft(find.text('Check status')).dy, lessThan(624));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the VA number uses the reference font', (tester) async {
      await pumpVa(tester);
      final context = tester.element(vaNumber);
      expect(
        tester.widget<SelectableText>(vaNumber).style?.fontFamily,
        PaymentTheme.of(context).referenceFontFamily,
      );
    });

    testWidgets('steps are collapsed, numbered as text, with no circles', (
      tester,
    ) async {
      await pumpVa(tester);
      expect(find.text('Open your banking app'), findsNothing);
      await tester.ensureVisible(find.text('How to pay'));
      await tester.tap(find.text('How to pay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Open your banking app'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('an unknown outcome never shows an account to pay into', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          PaymentStatusView(
            attempt: _attempt(submission: SubmissionState.outcomeUnknown),
            onAction: (_) {},
            instructions: PaymentInstructions(
              instructions: va,
              clock: () => now,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PaymentInstructions), findsNothing);
    });
  });

  group('status screens at 200% text', () {
    Future<void> pumpUnknown(WidgetTester tester) async {
      tester.view.physicalSize = const Size(720, 1248);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          PaymentStatusView(
            attempt: _attempt(submission: SubmissionState.outcomeUnknown),
            amount: const Money.idr(102500),
            onAction: (_) {},
          ),
          textScale: 2,
          size: const Size(360, 624),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the action comes before the reference rows', (tester) async {
      await pumpUnknown(tester);
      expect(
        tester.getTopLeft(find.text('Check status')).dy,
        lessThan(tester.getTopLeft(find.text('Payment reference')).dy),
      );
    });

    testWidgets('the header icon grows and centers on the first line', (
      tester,
    ) async {
      await pumpUnknown(tester);
      final icon = find.descendant(
        of: find.byType(StatusHeader),
        matching: find.byType(Icon),
      );
      expect(tester.getSize(icon), const Size(32, 32));
      final titleTop = tester
          .getTopLeft(find.text('Result not confirmed yet'))
          .dy;
      // Half of one 15/20 line at 2×.
      expect(
        tester.getCenter(icon).dy - titleTop,
        closeTo(15 * 2 * 20 / 15 / 2, 1),
      );
    });

    testWidgets('unknown detail no longer repeats the button', (tester) async {
      await pumpUnknown(tester);
      expect(find.textContaining('Check the status'), findsNothing);
    });
  });

  testWidgets('InfoRow keeps a short row on one line at 200% text', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 328,
            child: InfoRow(label: 'Fee', value: AmountText(Money.idr(2500))),
          ),
        ),
        textScale: 2,
      ),
    );
    expect(tester.getSize(find.byType(InfoRow)).width, 328);
    expect(
      tester.getTopLeft(find.text('Fee')).dy,
      tester.getTopLeft(find.text('Rp2,500')).dy,
    );
  });

  for (final language in ['en', 'id']) {
    testWidgets('200% text on a 320 pt screen does not overflow ($language)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              PaymentConfirmation(
                quote: _changedQuote,
                previousQuote: _quote,
                method: _balance,
                onConfirm: () async {},
              ),
              PaymentStatusView(
                attempt: _attempt(
                  status: PaymentStatus.pending,
                  actions: {
                    PaymentAction.checkStatus,
                    PaymentAction.requestCancel,
                  },
                ),
                amount: const Money.idr(1250000000),
                onAction: (_) {},
                instructions: PaymentInstructions(
                  instructions: VirtualAccountInstructions(
                    providerLabel: 'Bank Contoh',
                    accountNumber: '8808 0012 3456 7890',
                    amount: const Money.idr(1250000000),
                    expiresAt: DateTime.utc(2026, 10, 30, 11),
                    steps: const ['Open your banking app'],
                  ),
                  clock: () => DateTime.utc(2026, 10, 30, 10),
                  onCopyNumber: (_) async => true,
                ),
              ),
            ],
          ),
          language: language,
          textScale: 2,
          size: const Size(320, 568),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
