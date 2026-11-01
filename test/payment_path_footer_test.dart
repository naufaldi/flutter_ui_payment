import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

// D62: given a bounded height, the payment-path widgets pin their priority
// action to a footer; inside a scroll view they keep the inline layout.

Widget screen(Widget child, {double scale = 1, String language = 'en'}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        PaymentLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

Widget inList(Widget child) => screen(ListView(children: [child]));

final _quote = PaymentQuote(
  id: 'Q-1',
  revision: 1,
  lines: [
    for (var i = 0; i < 8; i++)
      QuoteLine(label: 'Item ${i + 1}', amount: const Money.idr(12500)),
  ],
  total: const Money.idr(100000),
  expiresAt: DateTime.utc(2030),
  methodId: 'balance',
);

const _balance = PaymentMethod(
  id: 'balance',
  label: 'Ruang Bayar balance',
  kind: PaymentMethodKind.balance,
  detail: 'Balance Rp350.000',
);

PaymentAttempt _attempt(Set<PaymentAction> actions) => PaymentAttempt(
  attemptId: 'att-1',
  quoteId: 'Q-1',
  quoteRevision: 1,
  methodId: 'balance',
  submission: SubmissionState.accepted,
  observation: Observation.fresh,
  snapshot: PaymentStatusSnapshot(
    attemptId: 'att-1',
    serverReference: 'TRX-004071',
    status: PaymentStatus.pending,
    revision: 2,
    updatedAt: DateTime.utc(2026, 10, 30, 9),
    allowedActions: actions,
  ),
);

/// Long host content above each widget, so its own content must scroll.
const _tall = SizedBox(key: Key('host-header'), height: 900);

final _cases = <String, Widget Function(Widget? header)>{
  'PaymentConfirmation': (header) => PaymentConfirmation(
    quote: _quote,
    method: _balance,
    onConfirm: () async {},
    footnote: 'You can cancel before paying.',
    header: header,
  ),
  'AuthorizationPrompt': (header) => AuthorizationPrompt(
    phase: AuthorizationPhase.ready,
    onStart: () {},
    onBackToReview: () {},
    header: header,
  ),
  'PaymentStatusView': (header) => PaymentStatusView(
    attempt: _attempt({
      PaymentAction.checkStatus,
      PaymentAction.requestCancel,
      PaymentAction.contactSupport,
    }),
    amount: const Money.idr(100000),
    onAction: (_) {},
    header: header,
  ),
  'VerificationIntro': (header) => VerificationIntro(
    requirements: const [
      DataRequirement(title: 'ID card', purpose: 'To match your name'),
      DataRequirement(title: 'Selfie', purpose: 'To match your face'),
    ],
    onOpenPolicy: () {},
    onContinue: () {},
    header: header,
  ),
  'VerificationStatusView': (header) => VerificationStatusView(
    snapshot: VerificationSnapshot(
      status: VerificationStatus.actionRequired,
      safeReason: 'The ID photo is blurry.',
      allowedActions: const {
        VerificationAction.fixDetails,
        VerificationAction.contactSupport,
      },
      updatedAt: DateTime.utc(2026, 10, 30, 9),
    ),
    onAction: (_) {},
    header: header,
  ),
};

Finder _variant(PaymentButtonVariant v) =>
    find.byWidgetPredicate((w) => w is PaymentButton && w.variant == v);

bool _scrolls(WidgetTester t, Finder f) => find
    .ancestor(of: f, matching: find.byType(Scrollable))
    .evaluate()
    .isNotEmpty;

void _surface(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  for (final MapEntry(key: name, value: build) in _cases.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$name pins its primary at 375×667, ${scale}x', (t) async {
        _surface(t, const Size(375, 667));
        await t.pumpWidget(screen(build(_tall), scale: scale));
        await t.pump();
        expect(t.takeException(), isNull);
        final primary = _variant(PaymentButtonVariant.primary);
        expect(primary, findsOneWidget);
        // On screen and tappable without scrolling, at the bottom.
        expect(_scrolls(t, primary), isFalse);
        expect(primary.hitTestable(), findsOneWidget);
        final rect = t.getRect(primary);
        expect(rect.bottom, lessThanOrEqualTo(667));
        expect(rect.top, greaterThan(667 / 2));
        // The footer holds the primary and at most one quiet action.
        final footer = find
            .byType(PaymentButton)
            .evaluate()
            .where(
              (e) => find
                  .ancestor(
                    of: find.byWidget(e.widget),
                    matching: find.byType(Scrollable),
                  )
                  .evaluate()
                  .isEmpty,
            )
            .map((e) => e.widget as PaymentButton)
            .toList();
        expect(
          footer.where((b) => b.variant == PaymentButtonVariant.primary),
          hasLength(1),
        );
        expect(
          footer
              .where((b) => b.variant != PaymentButtonVariant.primary)
              .every((b) => b.variant == PaymentButtonVariant.quiet),
          isTrue,
        );
        expect(footer.length, lessThanOrEqualTo(2));
        // The host header renders inside the scroll region.
        expect(find.byKey(const Key('host-header')), findsOneWidget);
        expect(_scrolls(t, find.byKey(const Key('host-header'))), isTrue);
      });
    }

    testWidgets('$name keeps its actions inline in a ListView', (t) async {
      _surface(t, const Size(375, 667));
      await t.pumpWidget(inList(build(null)));
      await t.pump();
      expect(t.takeException(), isNull);
      for (final e in find.byType(PaymentButton).evaluate()) {
        expect(_scrolls(t, find.byWidget(e.widget)), isTrue);
      }
    });
  }

  testWidgets('status: the quiet footer slot falls back to contact support', (
    t,
  ) async {
    _surface(t, const Size(375, 667));
    await t.pumpWidget(screen(_cases['PaymentStatusView']!(null)));
    await t.pump();
    final support = find.widgetWithText(PaymentButton, 'Contact support');
    final cancel = find.widgetWithText(PaymentButton, 'Request cancellation');
    expect(_scrolls(t, support), isFalse);
    expect(
      t.widget<PaymentButton>(support).variant,
      PaymentButtonVariant.quiet,
    );
    // Other actions stay in the content as hug buttons (D59).
    expect(_scrolls(t, cancel), isTrue);
    expect(t.widget<PaymentButton>(cancel).width, PaymentWidth.hug);
  });

  testWidgets('status: a host secondaryAction takes the quiet slot', (t) async {
    _surface(t, const Size(375, 667));
    var done = 0;
    await t.pumpWidget(
      screen(
        PaymentStatusView(
          attempt: _attempt({
            PaymentAction.checkStatus,
            PaymentAction.contactSupport,
          }),
          onAction: (_) {},
          secondaryAction: PaymentButton(
            key: const Key('done'),
            label: 'Done',
            variant: PaymentButtonVariant.quiet,
            onPressed: () => done++,
          ),
        ),
      ),
    );
    await t.pump();
    expect(_scrolls(t, find.byKey(const Key('done'))), isFalse);
    expect(
      _scrolls(t, find.widgetWithText(PaymentButton, 'Contact support')),
      isTrue,
    );
    await t.tap(find.byKey(const Key('done')));
    expect(done, 1);
  });

  testWidgets('status: secondaryAction must be quiet', (t) async {
    await t.pumpWidget(
      screen(
        PaymentStatusView(
          attempt: _attempt({PaymentAction.checkStatus}),
          onAction: (_) {},
          secondaryAction: PaymentButton(label: 'Done', onPressed: () {}),
        ),
      ),
    );
    expect(t.takeException(), isAssertionError);
  });

  testWidgets('status: the secondaryAction follows the actions inline', (
    t,
  ) async {
    _surface(t, const Size(375, 667));
    await t.pumpWidget(
      inList(
        PaymentStatusView(
          attempt: _attempt({PaymentAction.checkStatus}),
          onAction: (_) {},
          secondaryAction: PaymentButton(
            key: const Key('done'),
            label: 'Done',
            variant: PaymentButtonVariant.quiet,
            onPressed: () {},
          ),
        ),
      ),
    );
    await t.pump();
    final check = find.widgetWithText(PaymentButton, 'Check status');
    expect(
      t.getRect(find.byKey(const Key('done'))).top,
      greaterThan(t.getRect(check).bottom),
    );
  });

  testWidgets('authorization: approved has no footer', (t) async {
    _surface(t, const Size(375, 667));
    await t.pumpWidget(
      screen(
        AuthorizationPrompt(
          phase: AuthorizationPhase.approved,
          onStart: () {},
          onBackToReview: () {},
        ),
      ),
    );
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byType(PaymentButton), findsNothing);
  });

  testWidgets('intro: the consent hint sits with the pinned Continue', (
    t,
  ) async {
    _surface(t, const Size(375, 667));
    await t.pumpWidget(screen(_cases['VerificationIntro']!(_tall), scale: 2));
    await t.pump();
    final hint = find.text('Give consent to continue.');
    expect(hint, findsOneWidget);
    expect(_scrolls(t, hint), isFalse);
    expect(hint.hitTestable(), findsOneWidget);
  });
}
