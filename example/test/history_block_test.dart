import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/history_block_demo.dart';

TransactionRecord _record(String id) => TransactionRecord(
  id: id,
  title: id,
  amount: const Money.idr(15000),
  createdAt: DateTime(2026, 11, 4),
  status: PaymentStatus.succeeded,
);

void main() {
  testWidgets('retry announces a fresh failure and appends the same cursor', (
    tester,
  ) async {
    final nextPage = Completer<HistoryPage>();
    final retry = Completer<HistoryPage>();
    final requests = <String?>[];
    await tester.pumpWidget(
      HistoryBlockDemo(
        fetchPage: (_, _, cursor) {
          requests.add(cursor);
          if (cursor == null) {
            return Future.value((
              records: [_record('First row')],
              nextCursor: 'opaque-next',
            ));
          }
          return switch (requests.length) {
            2 => nextPage.future,
            3 => Future.error(StateError('immediate retry failure')),
            _ => retry.future,
          };
        },
      ),
    );
    await tester.pumpAndSettle();
    final load = find.text('Muat lagi');
    await tester.tap(load);
    await tester.tap(load);
    await tester.pump();
    expect(find.text('First row'), findsOneWidget);
    expect(requests, [null, 'opaque-next']);

    nextPage.completeError(StateError('private transport details'));
    await tester.pumpAndSettle();
    expect(find.text('First row'), findsOneWidget);
    expect(find.textContaining('private transport details'), findsNothing);
    final retryButton = find.text(PaymentLocalizations('id').retry);
    final error = find.textContaining('Halaman berikutnya gagal dimuat.');
    final firstErrorNode = tester.getSemantics(error).id;
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
    expect(requests, [null, 'opaque-next', 'opaque-next']);
    final secondErrorNode = tester.getSemantics(error);
    expect(secondErrorNode.id, isNot(firstErrorNode));
    expect(secondErrorNode.flagsCollection.isLiveRegion, isTrue);
    expect(secondErrorNode.flagsCollection.isHidden, isFalse);
    await tester.tap(retryButton);
    expect(requests, [null, 'opaque-next', 'opaque-next', 'opaque-next']);
    retry.complete((records: [_record('Second row')], nextCursor: null));
    await tester.pumpAndSettle();
    expect(find.text('First row'), findsOneWidget);
    expect(find.text('Second row'), findsOneWidget);
    expect(load, findsNothing);
  });

  for (final interruptReveal in [false, true]) {
    testWidgets(
      interruptReveal
          ? 'dragging away during reveal defers the page failure live label'
          : 'page failure publishes its live label after the reveal',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final nextPage = Completer<HistoryPage>();
        await tester.pumpWidget(
          HistoryBlockDemo(
            fetchPage: (_, _, cursor) => cursor == null
                ? Future.value((
                    records: List.generate(
                      12,
                      (index) => _record('Row $index'),
                    ),
                    nextCursor: 'opaque-next',
                  ))
                : nextPage.future,
          ),
        );
        await tester.pumpAndSettle();
        final scroll = find.byType(Scrollable).first;
        final load = find.text('Muat lagi');
        await tester.scrollUntilVisible(load, 200, scrollable: scroll);
        final button = find.ancestor(
          of: load,
          matching: find.byType(PaymentButton),
        );
        final position = tester.state<ScrollableState>(scroll).position;
        final viewport = tester.getRect(find.byType(CustomScrollView));
        position.jumpTo(
          position.pixels + tester.getRect(button).bottom - viewport.bottom,
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(button).bottom, closeTo(viewport.bottom, 1));
        await tester.tap(load.hitTestable());
        await tester.pump();

        const message =
            'Halaman berikutnya gagal dimuat. Transaksi sebelumnya tetap tersedia.';
        final error = find.text(message);
        final retry = find.text(PaymentLocalizations('id').retry);
        nextPage.completeError(StateError('Synthetic page failure'));
        await tester.pump();
        expect(
          tester.getRect(error).top,
          greaterThanOrEqualTo(viewport.bottom),
        );
        final beforeReveal = tester.getSemantics(error).getSemanticsData();
        expect(beforeReveal.label, isEmpty);
        expect(beforeReveal.flagsCollection.isHidden, isTrue);

        if (interruptReveal) {
          final revealOffset = position.pixels;
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, 120),
          );
          final draggedOffset = position.pixels;
          expect(draggedOffset, lessThan(revealOffset));
          await tester.pumpAndSettle();
          expect(position.pixels, draggedOffset);
          final interrupted = tester.getSemantics(error).getSemanticsData();
          expect(interrupted.flagsCollection.isHidden, isTrue);
          expect(interrupted.label, isEmpty);

          await tester.ensureVisible(error);
        }
        await tester.pump();
        expect(retry.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(error).bottom,
          lessThanOrEqualTo(viewport.bottom + 0.1),
        );
        final afterReveal = tester.getSemantics(error).getSemanticsData();
        expect(afterReveal.label, message);
        expect(afterReveal.flagsCollection.isLiveRegion, isTrue);
        expect(afterReveal.flagsCollection.isHidden, isFalse);
      },
    );
  }

  testWidgets('a page failure does not pull readers back to the footer', (
    tester,
  ) async {
    final nextPage = Completer<HistoryPage>();
    await tester.pumpWidget(
      HistoryBlockDemo(
        fetchPage: (_, _, cursor) => cursor == null
            ? Future.value((
                records: List.generate(12, (index) => _record('Row $index')),
                nextCursor: 'opaque-next',
              ))
            : nextPage.future,
      ),
    );
    await tester.pumpAndSettle();
    final scroll = find.byType(Scrollable).first;
    final load = find.text('Muat lagi');
    await tester.scrollUntilVisible(load, 200, scrollable: scroll);
    await tester.tap(load.hitTestable());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Row 0'),
      -200,
      scrollable: scroll,
    );
    await tester.pump();
    expect(find.text('Row 0').hitTestable(), findsOneWidget);

    nextPage.completeError(StateError('Synthetic page failure'));
    await tester.pumpAndSettle();
    expect(find.text('Row 0').hitTestable(), findsOneWidget);
    final retry = find.text(PaymentLocalizations('id').retry);
    expect(retry.hitTestable(), findsNothing);
    await tester.scrollUntilVisible(retry, 200, scrollable: scroll);
    expect(retry.hitTestable(), findsOneWidget);
  });

  testWidgets('new query rejects a late page and a late filter error', (
    tester,
  ) async {
    final oldPage = Completer<HistoryPage>();
    final filteredPage = Completer<HistoryPage>();
    final currentPage = Completer<HistoryPage>();
    final requests = <(String, TransactionFilter, String?)>[];
    const filter = TransactionFilter.succeeded;
    await tester.pumpWidget(
      HistoryBlockDemo(
        fetchPage: (query, status, cursor) {
          requests.add((query, status, cursor));
          if (cursor != null) return oldPage.future;
          if (query.isNotEmpty) return currentPage.future;
          if (status == filter) return filteredPage.future;
          return Future.value((
            records: [_record('Original row')],
            nextCursor: 'original-next',
          ));
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat lagi'));
    await tester.pump();
    final l10n = PaymentLocalizations('id');
    await tester.tap(find.text(l10n.transactionFilterLabel(filter)));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'replacement');
    await tester.pump();
    expect(requests, [
      ('', TransactionFilter.all, null),
      ('', TransactionFilter.all, 'original-next'),
      ('', filter, null),
      ('replacement', filter, null),
    ]);
    filteredPage.completeError(StateError('Filtered request failed late'));
    await tester.pump();
    expect(find.byType(LoadingSkeleton), findsOneWidget);
    expect(find.text(l10n.retry), findsNothing);

    currentPage.complete((records: [_record('Current row')], nextCursor: null));
    await tester.pumpAndSettle();
    oldPage.complete((
      records: [_record('Stale row')],
      nextCursor: 'stale-next',
    ));
    await tester.pumpAndSettle();
    expect(find.text('Current row'), findsOneWidget);
    expect(find.text('Original row'), findsNothing);
    expect(find.text('Stale row'), findsNothing);
    expect(find.text('Muat lagi'), findsNothing);
    expect(find.text(l10n.retry), findsNothing);
  });

  testWidgets('search keeps unknown inspectable and refunds separate', (
    tester,
  ) async {
    await tester.pumpWidget(
      const HistoryBlockDemo(fixtureDelay: Duration.zero),
    );
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
      const HistoryBlockDemo(
        initialState: HistoryDemoState.error,
        fixtureDelay: Duration.zero,
      ),
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
      await tester.pumpWidget(
        const HistoryBlockDemo(initialDark: true, fixtureDelay: Duration.zero),
      );
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
