import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/refund_detail_demo.dart';

import 'support/small_screen.dart';

TransactionRecord recordOf(WidgetTester tester) =>
    tester.widget<TransactionDetail>(find.byType(TransactionDetail)).record;

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the original payment keeps its success and amount while the '
      'refund moves from pending to partial', (tester) async {
    await tester.pumpWidget(const RefundDetailDemo(delay: Duration.zero));
    await tester.pumpAndSettle();
    expect(recordOf(tester).status, PaymentStatus.succeeded);
    expect(recordOf(tester).refund.status, RefundStatus.pending);

    await tapText(tester, 'Perbarui status refund');
    final record = recordOf(tester);
    expect(record.status, PaymentStatus.succeeded);
    expect(record.amount, refundOriginalAmount);
    expect(record.refund.status, RefundStatus.partial);
    // A final refund has nothing left to check.
    expect(buttonLabeled('Perbarui status refund'), findsNothing);

    await tapText(tester, 'Lihat struk');
    expect(find.text('Struk pembayaran'), findsOneWidget);
    expect(find.byType(PaymentReceipt), findsOneWidget);
    await tapText(tester, 'Tutup');
    expect(find.byType(PaymentReceipt), findsNothing);
  });

  testWidgets('a failed refund check keeps the last known status and can be '
      'retried', (tester) async {
    await tester.pumpWidget(
      const RefundDetailDemo(
        initialScenario: RefundDemoScenario.refreshFails,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Perbarui status refund');
    expect(find.text('Status refund belum diperbarui'), findsOneWidget);
    expect(recordOf(tester).refund.status, RefundStatus.pending);

    await tapText(tester, 'Perbarui status refund');
    expect(find.text('Status refund belum diperbarui'), findsNothing);
    expect(recordOf(tester).refund.status, RefundStatus.partial);
  });

  testWidgets('320dp at 200% text in dark mode keeps the refund action '
      'reachable', (tester) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      const RefundDetailDemo(initialDark: true, delay: Duration.zero),
    );
    await tester.pumpAndSettle();
    expect(find.text('Perbarui status refund').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
