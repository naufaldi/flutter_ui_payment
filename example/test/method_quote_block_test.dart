import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/method_quote_demo.dart';

import 'support/small_screen.dart';

Finder payButton() => find.byWidgetPredicate(
  (w) => w is PaymentButton && w.label.startsWith('Bayar '),
);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a late quote for an earlier choice cannot enable Continue', (
    tester,
  ) async {
    final pending = <String, Completer<PaymentQuote>>{};
    await tester.pumpWidget(
      MethodQuoteDemo(
        quoteFor: (id) => (pending[id] = Completer<PaymentQuote>()).future,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Virtual account');
    await tapText(tester, 'QRIS');

    pending['va']!.complete(methodQuoteFixture('va'));
    await tester.pumpAndSettle();
    expect(enabled(tester, 'Lanjutkan'), isFalse);
    expect(find.byType(PaymentSummary), findsNothing);

    pending['qris']!.complete(methodQuoteFixture('qris'));
    await tester.pumpAndSettle();
    expect(enabled(tester, 'Lanjutkan · Rp251.750'), isTrue);
    expect(
      tester.widget<PaymentSummary>(find.byType(PaymentSummary)).quote.methodId,
      'qris',
    );
  });

  testWidgets('when the host re-prices at submit, Pay waits for the payer to '
      'accept the new total', (tester) async {
    await tester.pumpWidget(
      const MethodQuoteDemo(
        initialScenario: MethodQuoteScenario.repriced,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Virtual account');
    await tapText(tester, 'Lanjutkan · Rp254.000');
    await tester.tap(payButton());
    await tester.pumpAndSettle();

    final l10n = PaymentLocalizations('id');
    expect(find.text(l10n.totalChangedTitle), findsOneWidget);
    expect(tester.widget<PaymentButton>(payButton()).onPressed, isNull);

    final accept = find.textContaining('Saya sudah meninjau total baru');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    await tester.tap(payButton());
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PaymentStatusView>(find.byType(PaymentStatusView))
          .attempt
          .quoteRevision,
      2,
    );
  });

  testWidgets('an unavailable method says why, and a pricing failure offers '
      'a retry instead of a total', (tester) async {
    await tester.pumpWidget(
      const MethodQuoteDemo(
        initialScenario: MethodQuoteScenario.quoteError,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum didukung merchant ini'), findsOneWidget);

    await tapText(tester, 'Virtual account');
    expect(find.text('Biaya belum dapat dihitung'), findsOneWidget);
    expect(enabled(tester, 'Lanjutkan'), isFalse);

    await tapText(tester, 'Coba lagi');
    expect(find.byType(PaymentSummary), findsOneWidget);
    expect(enabled(tester, 'Lanjutkan · Rp254.000'), isTrue);
  });

  testWidgets('320dp at 200% text in dark mode keeps the method list and '
      'Continue reachable', (tester) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      const MethodQuoteDemo(initialDark: true, delay: Duration.zero),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Virtual account');
    expect(find.text('Lanjutkan · Rp254.000').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
