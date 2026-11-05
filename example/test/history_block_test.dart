import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/history_block_demo.dart';

void main() {
  testWidgets('search keeps unknown inspectable and refunds separate', (
    tester,
  ) async {
    await tester.pumpWidget(const HistoryBlockDemo());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'INV-2047');
    await tester.pumpAndSettle();
    expect(find.text('INV-2048'), findsNothing);
    await tester.tap(find.widgetWithText(TransactionListItem, 'INV-2047'));
    await tester.pumpAndSettle();
    expect(
      find.text(PaymentLocalizations('id').statusUnknownLead),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'^Bayar Rp')), findsNothing);
    await tester.tap(find.text('Kembali ke riwayat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'INV-2044');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TransactionListItem, 'INV-2044'));
    await tester.pumpAndSettle();
    expect(find.byType(RefundSection), findsOneWidget);
    final detail = tester.widget<TransactionDetail>(
      find.byType(TransactionDetail),
    );
    expect(detail.record.status, PaymentStatus.succeeded);
    expect(detail.record.refund.status, RefundStatus.partial);
  });

  testWidgets('failed history retries and a no-match search resets query', (
    tester,
  ) async {
    await tester.pumpWidget(
      const HistoryBlockDemo(initialState: HistoryDemoState.error),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(PaymentLocalizations('id').retry));
    await tester.pumpAndSettle();
    expect(find.text('INV-2048'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'missing-reference');
    await tester.pumpAndSettle();
    expect(
      find.text(PaymentLocalizations('id').noMatchesTitle),
      findsOneWidget,
    );
    await tester.tap(find.text(PaymentLocalizations('id').resetFilters));
    await tester.pumpAndSettle();
    expect(find.text('INV-2048'), findsOneWidget);
  });

  testWidgets(
    '320dp/200% dark history keeps filter and detail return reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const HistoryBlockDemo(initialDark: true));
      await tester.pumpAndSettle();
      final filter = find.byTooltip(PaymentLocalizations('id').filterByStatus);
      expect(filter.hitTestable(), findsOneWidget);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .text(
              PaymentLocalizations(
                'id',
              ).transactionFilterLabel(TransactionFilter.inProgress),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.text('INV-2048'), findsNothing);
      await tester.enterText(find.byType(EditableText), 'INV-2047');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('INV-2047').last,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('INV-2047').last);
      await tester.pumpAndSettle();
      expect(find.text('Kembali ke riwayat').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
