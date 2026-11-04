import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/compositions/host_checkout.dart';

final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3355AA));
final payment = PaymentTheme.fromColorScheme(scheme);

final order = CheckoutOrder(
  merchant: 'Ruang Bayar Akademi',
  reference: 'INV-2026-1103',
  quote: PaymentQuote(
    id: 'Q-HOST',
    revision: 1,
    lines: const [
      QuoteLine(label: 'Paket Belajar', amount: Money.idr(100000)),
      QuoteLine(
        label: 'Biaya layanan',
        amount: Money.idr(2500),
        kind: QuoteLineKind.fee,
      ),
    ],
    total: const Money.idr(102500),
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    methodId: 'balance',
  ),
  methods: const [
    PaymentMethod(
      id: 'balance',
      label: 'Saldo Ruang Bayar',
      kind: PaymentMethodKind.balance,
    ),
  ],
  selectedMethodId: 'balance',
  balance: const Money.idr(350000),
  balanceState: BalanceState.sufficient,
);

Widget host(CheckoutActions actions, {double scale = 1, CheckoutOrder? data}) =>
    MaterialApp(
      theme: ThemeData(colorScheme: scheme, extensions: [payment]),
      localizationsDelegates: const [PaymentLocalizations.delegate],
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: ProductLooks(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InvoiceCheckout(order: data ?? order, actions: actions),
                    const SizedBox(height: 48),
                    WalletReviewCheckout(
                      order: data ?? order,
                      actions: actions,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

Finder pay(int index) => find
    .ancestor(
      of: find.textContaining(RegExp(r'^Pay ')),
      matching: find.byType(FilledButton),
    )
    .at(index);

void main() {
  testWidgets('merchant verification badge requires a host verdict', (
    tester,
  ) async {
    final actions = CheckoutActions(
      onSelectMethod: (_) {},
      onChangeMethod: () {},
      onReceiptEmailChanged: (_) {},
      onPay: () async {},
    );
    await tester.pumpWidget(host(actions));
    expect(find.byIcon(Icons.verified_outlined), findsNothing);
    final verifiedOrder = CheckoutOrder(
      merchant: order.merchant,
      reference: order.reference,
      quote: order.quote,
      methods: order.methods,
      selectedMethodId: order.selectedMethodId,
      balance: order.balance,
      balanceState: order.balanceState,
      merchantVerified: true,
    );
    await tester.pumpWidget(host(actions, data: verifiedOrder));
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
  });
  testWidgets(
    'both layouts show the product look and pay through the same host '
    'callback, once per press',
    (tester) async {
      var pays = 0;
      var changes = 0;
      var pending = Completer<void>();
      final actions = CheckoutActions(
        onSelectMethod: (_) {},
        onChangeMethod: () => changes++,
        onReceiptEmailChanged: (_) {},
        onPay: () {
          pays++;
          return pending.future;
        },
      );
      await tester.pumpWidget(host(actions));

      // A long method action must not squeeze the balance heading into letters.
      expect(tester.getSize(find.text('Balance')).height, lessThan(40));

      final pill = BorderRadius.circular(payment.space(PaymentSpace.major));
      // The named pay preset and the product button corners, in both layouts.
      for (var i = 0; i < 2; i++) {
        final style = tester.widget<FilledButton>(pay(i)).style!;
        expect(style.backgroundColor!.resolve({}), payment.textPrimary);
        expect(
          (style.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
          pill,
        );
      }
      // The product field look on both receipt fields; no field takes style.
      final fields = find.byType(PaymentTextField);
      expect(fields, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        final decoration = tester
            .widget<InputDecorator>(
              find
                  .descendant(
                    of: fields.at(i),
                    matching: find.byType(InputDecorator),
                  )
                  .first,
            )
            .decoration;
        expect(decoration.fillColor, payment.surfaceMuted);
        expect(
          (decoration.enabledBorder! as OutlineInputBorder).borderRadius,
          BorderRadius.circular(payment.space(PaymentSpace.group)),
        );
      }

      // The invoice's pay locks while the host works.
      await tester.ensureVisible(pay(0));
      await tester.tap(pay(0));
      await tester.pump();
      await tester.tap(pay(0), warnIfMissed: false);
      await tester.pump();
      expect(pays, 1);
      pending.complete();
      await tester.pumpAndSettle();

      // The wallet review reports through the same callbacks.
      pending = Completer<void>()..complete();
      await tester.ensureVisible(find.text('Use another method'));
      await tester.tap(find.text('Use another method'));
      await tester.ensureVisible(pay(1));
      await tester.tap(pay(1));
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(pays, 2);
    },
  );

  testWidgets('at 320 dp and 200% text both pay actions stay reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var pays = 0;
    await tester.pumpWidget(
      host(
        CheckoutActions(
          onSelectMethod: (_) {},
          onChangeMethod: () {},
          onReceiptEmailChanged: (_) {},
          onPay: () async => pays++,
        ),
        scale: 2,
      ),
    );
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(pay(i));
      await tester.pumpAndSettle();
      expect(tester.getSize(pay(i)).height, greaterThanOrEqualTo(48));
      await tester.tap(pay(i));
      await tester.pumpAndSettle();
    }
    expect(pays, 2);
    expect(tester.takeException(), isNull);
  });
}
