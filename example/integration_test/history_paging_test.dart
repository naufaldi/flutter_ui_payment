import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/history_block_demo.dart';

import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('paged history keeps rows through a next-page retry', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final scroll = find.byType(Scrollable).first;
    final load = find.text('Muat lagi');
    final retry = find.text(PaymentLocalizations('id').retry);
    final error = find.textContaining('Halaman berikutnya gagal dimuat.');
    Finder row(String id) => find.widgetWithText(TransactionListItem, id);

    for (final (dark, scale, suffix) in [
      (false, 1.0, ''),
      (true, 1.0, '_dark'),
      (false, 2.0, '_200'),
      (true, 2.0, '_dark_200'),
    ]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      await tester.pumpWidget(
        HistoryBlockDemo(
          key: UniqueKey(),
          initialDark: dark,
          initialState: HistoryDemoState.nextPageError,
          fixtureDelay: Duration.zero,
        ),
      );
      await tester.pumpAndSettle();
      await capture(binding, tester, 'android_block_history$suffix');
      expect(row('INV-2045'), findsNothing);

      await tester.scrollUntilVisible(load, 100, scrollable: scroll);
      await tester.pumpAndSettle();
      await tester.tap(load.hitTestable());
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      await Scrollable.ensureVisible(tester.element(error), alignment: 1);
      await tester.pumpAndSettle();
      expect(row('INV-2046').hitTestable(), findsOneWidget);
      await capture(binding, tester, 'android_block_history_page_error$suffix');
      await tester.tap(retry.hitTestable());
      await tester.pumpAndSettle();

      final appended = row('INV-2045');
      await tester.scrollUntilVisible(appended, 100, scrollable: scroll);
      await tester.pumpAndSettle();
      expect(appended.hitTestable(), findsOneWidget);
      expect(retry, findsNothing);
      final search = find.byType(EditableText);
      await tester.scrollUntilVisible(search, -120, scrollable: scroll);
      await tester.pumpAndSettle();
      // This result is not in either page already loaded.
      await tester.enterText(search, 'INV-2020');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(row('INV-2020'), findsOneWidget);
      expect(row('INV-2045'), findsNothing);
      expect(load, findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
