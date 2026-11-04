import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/compositions/payment_preferences_block.dart';
import 'package:flutter_ui_payment_example/payment_preferences_demo.dart';

import 'support/small_screen.dart';

PaymentPreferencesBlock blockOf(WidgetTester tester) =>
    tester.widget(find.byType(PaymentPreferencesBlock));

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a failed save keeps the edit and never says saved; the retry '
      'is confirmed by the host', (tester) async {
    await tester.pumpWidget(
      const PaymentPreferencesDemo(
        initialScenario: PreferencesScenario.firstSaveFails,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Virtual account');
    expect(find.text('Ada perubahan yang belum disimpan.'), findsOneWidget);

    await tapText(tester, 'Simpan');
    expect(find.textContaining('Belum tersimpan.'), findsOneWidget);
    expect(find.text('Preferensi tersimpan.'), findsNothing);
    expect(blockOf(tester).draft.defaultMethodId, 'va');
    expect(blockOf(tester).saved.defaultMethodId, 'balance');

    await tapText(tester, 'Simpan');
    expect(find.text('Preferensi tersimpan.'), findsOneWidget);
    expect(blockOf(tester).saved.defaultMethodId, 'va');
  });

  testWidgets('choices lock while the host saves, and an unavailable method '
      'explains why', (tester) async {
    await tester.pumpWidget(
      const PaymentPreferencesDemo(delay: Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Tambahkan kartu dulu di Metode tersimpan.'),
      findsOneWidget,
    );
    await tapText(tester, 'Kartu kredit');
    expect(blockOf(tester).draft.defaultMethodId, 'balance');

    await tapText(tester, 'Pengingat tagihan');
    await tester.tap(find.text('Simpan'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Menyimpan perubahan…'), findsOneWidget);
    await tester.tap(find.text('QRIS'), warnIfMissed: false);
    await tester.pump();
    expect(blockOf(tester).draft.defaultMethodId, 'balance');
    await tester.pumpAndSettle();
    expect(find.text('Preferensi tersimpan.'), findsOneWidget);
    expect(blockOf(tester).saved.reminders, isTrue);
  });

  testWidgets('320dp at 200% text in dark mode keeps Save reachable with '
      '48dp rows', (tester) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      const PaymentPreferencesDemo(initialDark: true, delay: Duration.zero),
    );
    await tester.pumpAndSettle();
    expect(find.text('Simpan').hitTestable(), findsOneWidget);
    expect(
      tester.getSize(find.byType(PaymentRadio<String>).first).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });
}
