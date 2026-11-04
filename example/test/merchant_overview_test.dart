import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/compositions/merchant_overview.dart';
import 'package:flutter_ui_payment_example/merchant_demo.dart';

void main() {
  testWidgets('merchant inspects unknown payments without creating a payment', (
    tester,
  ) async {
    await tester.pumpWidget(const MerchantDemo());
    await tester.pumpAndSettle();
    expect(find.text('Saldo tersedia'), findsOneWidget);
    expect(find.text('3 pembayaran perlu dicek'), findsOneWidget);
    final action = find.widgetWithText(PaymentLink, 'Periksa transaksi');
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran belum diketahui'), findsOneWidget);
    expect(find.text('INV-2048'), findsNothing);
    await tester.tap(find.text('INV-2047'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentSheet), findsOneWidget);
    expect(find.text('Detail transaksi'), findsOneWidget);
    expect(find.text('Belum terkonfirmasi'), findsOneWidget);
    expect(
      find.textContaining('sebelum meminta pelanggan membayar ulang'),
      findsOneWidget,
    );
    expect(
      find.text('Demo · Data sintetis. Tidak ada pembayaran dikirim.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Kembali ke transaksi'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentSheet), findsNothing);
    expect(find.text('Pembayaran belum diketahui'), findsOneWidget);
    await tester.tap(find.text('Tampilkan semua transaksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INV-2048'));
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran berhasil'), findsOneWidget);
    expect(find.text('Belum terkonfirmasi'), findsNothing);
  });

  testWidgets('320dp at 200 percent keeps details and navigation reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const MerchantDemo());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ringkasan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('INV-2047'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('INV-2047'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('INV-2047'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final back = find.widgetWithText(PaymentButton, 'Kembali ke transaksi');
    expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    expect(back.hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Demo · Data sintetis'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(PaymentSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byType(PaymentSheet), findsNothing);
  });

  testWidgets('empty host data keeps missing balance distinct from zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [PaymentLocalizations.delegate],
        home: Scaffold(
          body: MerchantOverview(
            data: const MerchantOverviewData(
              merchant: 'Toko baru',
              balance: null,
              revenue: Money.idr(0),
              period: 'Hari ini',
              points: [],
              methods: [],
              recent: [],
              unconfirmedCount: 0,
            ),
            onInspectUnconfirmed: () {},
            onViewTransactions: () {},
            onOpenTransaction: (_) {},
            onOpenAccount: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saldo belum tersedia'), findsOneWidget);
    expect(find.text('Periksa transaksi'), findsNothing);
    await tester.scrollUntilVisible(
      find.textContaining('Pembayaran pertama'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
