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
      final button = find.ancestor(
        of: load,
        matching: find.byType(PaymentButton),
      );
      final position = tester.state<ScrollableState>(scroll).position;
      final viewport = tester.getRect(find.byType(CustomScrollView));
      final edgeOffset =
          position.pixels + tester.getRect(button).bottom - viewport.bottom;
      position.jumpTo(
        edgeOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(button).bottom, closeTo(viewport.bottom, 24));
      await tester.tap(load.hitTestable());
      await tester.pumpAndSettle();
      await capture(binding, tester, 'android_block_history_page_error$suffix');
      for (final target in [retry, error]) {
        expect(target.hitTestable(), findsOneWidget);
        final rect = tester.getRect(target);
        expect(rect.top, greaterThanOrEqualTo(viewport.top));
        expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 0.1));
      }
      final errorSemantics = tester.getSemantics(error).flagsCollection;
      expect(errorSemantics.isLiveRegion, isTrue);
      expect(errorSemantics.isHidden, isFalse);
      expect(row('INV-2046').hitTestable(), findsOneWidget);
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
