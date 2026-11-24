import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/search_results_demo.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reader retries Find and jumps to the chosen matching page', (
    tester,
  ) async {
    await tester.pumpWidget(const SearchResultsDemo());
    await settle(tester);
    await tapVisible(tester, find.byTooltip('Skenario demo'));
    await tapVisible(tester, find.text('Gagal mencari sekali'));
    await tapVisible(
      tester,
      find.widgetWithText(PaymentButton, 'Cari di dokumen'),
    );
    await tester.enterText(find.byType(EditableText), 'garden');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await pumpUntilFound(tester, find.text('Pencarian gagal'));
    await tester.tap(find.widgetWithText(PaymentButton, 'Coba lagi'));
    final result = find.widgetWithText(PaymentListItem, 'Halaman 5');
    await pumpUntilFound(tester, result);
    expect(
      find.text('The garden wall is built from stone found on the property.'),
      findsOneWidget,
    );
    await tapVisible(tester, result);
    await settle(tester);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Halaman 5'), findsOneWidget);
    expect(find.text('Halaman 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
