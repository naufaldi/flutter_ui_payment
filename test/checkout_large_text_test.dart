import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

Widget host(
  Widget child, {
  String language = 'en',
  double textScale = 1,
  Size size = const Size(390, 844),
  Widget? bottomBar,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
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
        bottomNavigationBar: bottomBar,
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

void main() {
  testWidgets('summary drops its headline total at large text', (tester) async {
    await tester.pumpWidget(host(PaymentSummary(quote: _quote)));
    expect(find.text('Rp102,500'), findsNWidgets(2));

    await tester.pumpWidget(host(PaymentSummary(quote: _quote), textScale: 2));
    await tester.pumpAndSettle();
    // Only the Total row remains.
    expect(find.text('Rp102,500'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action bar caps its total at 1.6x and stacks Pay at 200%', (
    tester,
  ) async {
    const viewport = Size(320, 800);
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var presses = 0;
    Widget bar(double scale) => host(
      const SizedBox.shrink(),
      textScale: scale,
      size: viewport,
      bottomBar: PaymentActionBar(
        total: const Money.idr(102500),
        action: PaymentButton(
          label: 'Review payment',
          onPressed: () => presses++,
        ),
      ),
    );

    final pay = find.widgetWithText(PaymentButton, 'Review payment');
    final amount = find.text('Rp102,500');
    Rect totalBounds() => tester
        .getRect(find.text('Total'))
        .expandToInclude(tester.getRect(amount));
    await tester.pumpWidget(bar(1));
    final h1 = tester.getSize(amount).height;
    final compact = tester.getRect(pay);
    final compactTotal = totalBounds();
    expect(compact.left, greaterThanOrEqualTo(compactTotal.right));
    expect(
      compact.center.dy,
      inInclusiveRange(compactTotal.top, compactTotal.bottom),
    );
    await tester.tap(pay);
    await tester.pump();
    expect(presses, 1);

    await tester.pumpWidget(bar(2));
    await tester.pumpAndSettle();
    final h2 = tester.getSize(amount).height;

    expect(h2, greaterThan(h1));
    expect(h2, lessThanOrEqualTo(h1 * 1.6 + 1));
    final target = tester.getRect(pay);
    final stackedTotal = totalBounds();
    final footer = tester.getRect(find.byType(PaymentActionBar));
    expect(target.top, greaterThanOrEqualTo(stackedTotal.bottom));
    expect(target.left, closeTo(stackedTotal.left, 1));
    expect(target.center.dx, closeTo(footer.center.dx, 1));
    expect(target.width, greaterThan(compact.width));
    expect((Offset.zero & viewport).intersect(target), target);
    expect(target.width, greaterThanOrEqualTo(48));
    expect(target.height, greaterThanOrEqualTo(48));
    await tester.tap(pay);
    await tester.pump();
    expect(presses, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('balance caps its amount at 1.6x', (tester) async {
    Widget card(double scale) => host(
      const BalanceCard(
        state: BalanceState.sufficient,
        balance: Money.idr(250000),
      ),
      textScale: scale,
    );

    await tester.pumpWidget(card(1));
    final h1 = tester.getSize(find.text('Rp250,000')).height;

    await tester.pumpWidget(card(2));
    await tester.pumpAndSettle();
    final h2 = tester.getSize(find.text('Rp250,000')).height;

    expect(h2, greaterThan(h1));
    expect(h2, lessThanOrEqualTo(h1 * 1.6 + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('authorization boxes only the exceptions', (tester) async {
    Widget prompt(AuthorizationPhase phase) => host(
      AuthorizationPrompt(phase: phase, onStart: () {}, onBackToReview: () {}),
    );

    await tester.pumpWidget(prompt(AuthorizationPhase.ready));
    expect(find.byType(PaymentBanner), findsNothing);
    expect(find.text('Confirm payment'), findsOneWidget);

    await tester.pumpWidget(prompt(AuthorizationPhase.failed));
    expect(find.byType(PaymentBanner), findsOneWidget);
  });

  testWidgets('re-quote consent reads at summary row size', (tester) async {
    final changed = PaymentQuote(
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
    await tester.pumpWidget(
      host(
        PaymentConfirmation(
          quote: changed,
          previousQuote: _quote,
          method: const PaymentMethod(
            id: 'balance',
            label: 'Balance',
            kind: PaymentMethodKind.balance,
            detail: 'Rp250,000',
          ),
          onConfirm: () async {},
        ),
      ),
    );
    final consent = tester.widget<Text>(
      find.textContaining('reviewed the new total'),
    );
    expect(consent.style?.fontSize, 15);
    // The method name and its detail, not a label/value row.
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('Rp250,000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
