import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/compositions/report_problem_block.dart';
import 'package:rakit_ui_example/history_block_demo.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('history report retries with the draft and shows the host case', (
    tester,
  ) async {
    await tester.pumpWidget(const HistoryBlockDemo());
    await settle(tester);
    await tapVisible(tester, find.byTooltip('Skenario demo'));
    await tapVisible(tester, find.text('Gagal kirim laporan sekali'));
    await tapVisible(
      tester,
      find.widgetWithText(TransactionListItem, 'INV-2048'),
    );
    await tapVisible(tester, find.text('Laporkan masalah'));
    await settle(tester);
    final sheet = find.byKey(const Key('report-problem-sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('INV-2048')).hitTestable(),
      findsOneWidget,
    );
    await tapVisible(
      tester,
      find
          .descendant(
            of: find.byType(PaymentSelect<ReportProblemReason>),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tapVisible(tester, find.text('Terdebit dua kali'));
    final note = find.descendant(
      of: find.byType(PaymentTextArea),
      matching: find.byType(EditableText),
    );
    await tester.ensureVisible(note);
    await tester.enterText(note, 'Satu pesanan, dua tagihan.');
    final send = find.byKey(const Key('send-report'));
    await tapVisible(tester, send);
    await pumpUntilFound(tester, find.text('Belum ada ID kasus. Coba lagi.'));
    expect(find.text('Satu pesanan, dua tagihan.'), findsOneWidget);
    expect(find.text('Terdebit dua kali'), findsOneWidget);
    await tapVisible(tester, send);
    await pumpUntilFound(tester, find.text('CASE-DEMO-0001'));
    await tapVisible(tester, find.text('Selesai'));
    expect(find.text('Detail transaksi'), findsOneWidget);
    await tapVisible(tester, find.text('Kembali ke riwayat'));
    await settle(tester);
    expect(
      find.widgetWithText(TransactionListItem, 'INV-2048'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
