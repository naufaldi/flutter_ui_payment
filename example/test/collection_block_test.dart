import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/collection_block_demo.dart';
import 'package:rakit_ui_example/collection_page_demo.dart';
import 'package:rakit_ui_example/compositions/collection_block.dart';

const _pageError =
    'The next page couldn’t load. Your earlier items are still here.';
const _firstError = 'The collection couldn’t load. Try again.';
final _load = find.text('Load more');
final _retry = find.text('Retry');

CollectionDemoPage _page(String title, [String? cursor]) =>
    (rows: [(title: title, detail: 'PDF · 2 pages')], nextCursor: cursor);

Widget _shortCollection({
  required CollectionPageState state,
  required VoidCallback onRequest,
  Widget? header,
  bool hasRow = false,
}) => MaterialApp(
  home: Scaffold(
    body: CollectionBlock(
      header: header,
      rowCount: hasRow ? 1 : 0,
      rowBuilder: (_, _) => const Text('Earlier document'),
      pageState: state,
      firstEmpty: const StateMessage(
        icon: Icons.inbox_outlined,
        title: 'Empty',
      ),
      laterEmptyMessage: 'No more documents',
      errorTitle: 'First-page error',
      loadMoreLabel: 'Load more',
      retryLabel: 'Retry',
      onRequestPage: onRequest,
    ),
  ),
);

void main() {
  testWidgets('Previous is accessible without an out-of-range row index', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var previousRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentCollection(
            controller: controller,
            rowCount: 5,
            rowBuilder: (_, index) =>
                SizedBox(height: 72, child: Text('Document ${index + 1}')),
            footer: SizedBox(
              height: 64,
              child: PaymentButton(
                label: 'Previous',
                onPressed: () => previousRequests++,
              ),
            ),
          ),
        ),
      ),
    );
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();

    final lastRow = tester.getSemantics(find.text('Document 5'));
    final scroll = lastRow.parent!;
    final data = scroll.getSemanticsData();
    expect(data.scrollPosition, greaterThan(0));
    final count = data.scrollChildCount ?? 0;
    if (count > 0) {
      var visible = 0;
      scroll.visitChildren((child) {
        if (!child.flagsCollection.isHidden) visible++;
        return true;
      });
      // Android derives the last index from all visible direct children.
      expect((data.scrollIndex ?? 0) + visible - 1, lessThan(count));
    }

    final previous = find.semantics.byLabel('Previous');
    expect(previous, findsOne);
    expect(previous.evaluate().single.flagsCollection.isHidden, isFalse);
    tester.semantics.tap(previous);
    await tester.pump();
    expect(previousRequests, 1);
  });

  testWidgets('refresh keeps visible keyed row state after reordering', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var documents = ['A', 'B'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => documents = ['B', 'A']),
                  child: const Text('Refresh documents'),
                ),
                Expanded(
                  child: PaymentCollection(
                    rowCount: documents.length,
                    findItemIndexCallback: (key) {
                      final index = documents.indexOf(
                        (key as ValueKey<String>).value,
                      );
                      return index < 0 ? null : index;
                    },
                    rowBuilder: (_, index) {
                      final id = documents[index];
                      return ExpansionTile(
                        key: ValueKey(id),
                        title: Text('Document $id'),
                        children: [Text('Details $id')],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final rowA = find.text('Document A');
    final rowB = find.text('Document B');
    final detailsA = find.text('Details A');
    await tester.tap(rowA);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(rowA).dy, lessThan(tester.getTopLeft(rowB).dy));
    expect(detailsA.hitTestable(), findsOneWidget);

    await tester.tap(find.text('Refresh documents'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(rowB).dy, lessThan(tester.getTopLeft(rowA).dy));
    expect(detailsA.hitTestable(), findsOneWidget);
    expect(find.text('Details B').hitTestable(), findsNothing);
  });

  testWidgets('numbered collection retries, replaces and refreshes a page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const CollectionPageDemo());

    Future<void> tap(String label) async {
      final control = find.text(label);
      await tester.scrollUntilVisible(control, 100);
      await tester.tap(control.hitTestable());
      await tester.pump();
    }

    Future<void> finishRequest() async {
      await tester.pump(const Duration(milliseconds: 280));
      await tester.pumpAndSettle();
    }

    expect(find.text('Workshop notes'), findsOneWidget);
    await tap('Next');
    expect(find.text('Loading documents'), findsOneWidget);
    expect(find.text('Workshop notes'), findsNothing);
    await finishRequest();
    expect(find.text('Couldn’t load this page'), findsOneWidget);

    await tap('Try again');
    await finishRequest();
    expect(find.text('Reading list'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Workshop notes'), findsNothing);

    await tap('Next');
    await finishRequest();
    expect(find.text('No documents on this page'), findsOneWidget);
    expect(find.text('Page 3'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Reading list'), findsNothing);

    await tester.fling(
      find.text('No documents on this page').hitTestable(),
      const Offset(0, 380),
      1000,
    );
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Loading documents'), findsOneWidget);
    await finishRequest();
    expect(find.text('Page 3'), findsOneWidget);

    await tap('Previous');
    await finishRequest();
    expect(find.text('Reading list'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial loading resolves to first empty with a way forward', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CollectionBlockDemo(
        initialScenario: CollectionDemoScenario.firstEmpty,
      ),
    );
    expect(find.byType(LoadingSkeleton), findsOneWidget);
    expect(find.text('No documents yet'), findsNothing);
    expect(_load, findsNothing);

    await tester.pump(const Duration(milliseconds: 280));
    await tester.pumpAndSettle();
    expect(find.byType(LoadingSkeleton), findsNothing);
    expect(find.text('No documents yet'), findsOneWidget);
    await tester.tap(find.text('Add sample documents'));
    await tester.pump(const Duration(milliseconds: 280));
    await tester.pumpAndSettle();
    expect(find.text('Workshop notes'), findsOneWidget);
    expect(_load, findsOneWidget);
  });

  testWidgets('empty next page retains records and stops paging', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CollectionBlockDemo(
        initialScenario: CollectionDemoScenario.laterEmpty,
        fixtureDelay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_load);
    await tester.pumpAndSettle();
    expect(find.text('Workshop notes'), findsOneWidget);
    expect(find.text('No more documents on this page.'), findsOneWidget);
    expect(find.text('No documents yet'), findsNothing);
    expect(find.text('Add sample documents'), findsNothing);
    expect(_load, findsNothing);
    expect(_retry, findsNothing);
  });

  testWidgets('first-page Retry gets a fresh announcement and can recover', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      CollectionBlockDemo(
        fetchPage: (_) async {
          if (++requests < 3) throw StateError('private details');
          return _page('Recovered document');
        },
      ),
    );
    await tester.pumpAndSettle();
    final error = find.bySemanticsLabel(
      'Couldn’t load documents\n$_firstError',
    );
    final first = tester.getSemantics(error);
    expect(first.flagsCollection.isLiveRegion, isTrue);
    expect(first.flagsCollection.isHidden, isFalse);
    expect(find.textContaining('private details'), findsNothing);

    await tester.tap(_retry);
    await tester.pumpAndSettle();
    final second = tester.getSemantics(error);
    expect(second.id, isNot(first.id));
    expect(second.flagsCollection.isLiveRegion, isTrue);
    await tester.tap(_retry);
    await tester.pumpAndSettle();
    expect(find.text('Recovered document'), findsOneWidget);
    expect(error, findsNothing);
  });

  testWidgets('loading and retry preserve rows and the failed cursor', (
    tester,
  ) async {
    final pending = Completer<CollectionDemoPage>();
    final retry = Completer<CollectionDemoPage>();
    final requests = <String?>[];
    await tester.pumpWidget(
      CollectionBlockDemo(
        fetchPage: (cursor) {
          requests.add(cursor);
          return switch (requests.length) {
            1 => Future.value(_page('Earlier document', 'opaque-next')),
            2 => pending.future,
            3 => Future.error(StateError('immediate repeat failure')),
            _ => retry.future,
          };
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(_load);
    await tester.tap(_load);
    await tester.pump();
    expect(requests, [null, 'opaque-next']);
    expect(find.text('Earlier document'), findsOneWidget);
    expect(
      tester.widget<PaymentButton>(find.byType(PaymentButton)).busy,
      isTrue,
    );

    pending.completeError(StateError('page unavailable'));
    await tester.pumpAndSettle();
    final error = find.text(_pageError);
    final first = tester.getSemantics(error);
    expect(first.flagsCollection.isLiveRegion, isTrue);
    expect(find.text('Earlier document'), findsOneWidget);
    await tester.tap(_retry);
    await tester.pumpAndSettle();
    final second = tester.getSemantics(error);
    expect(second.id, isNot(first.id));
    expect(second.flagsCollection.isLiveRegion, isTrue);

    await tester.tap(_retry);
    expect(requests, [null, 'opaque-next', 'opaque-next', 'opaque-next']);
    retry.complete(_page('Appended document'));
    await tester.pumpAndSettle();
    expect(find.text('Earlier document'), findsOneWidget);
    expect(find.text('Appended document'), findsOneWidget);
    expect(_retry, findsNothing);
    expect(_load, findsNothing);
  });

  testWidgets(
    'offscreen failure has no live label until revealed at 320/200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final pending = Completer<CollectionDemoPage>();
      await tester.pumpWidget(
        CollectionBlockDemo(
          initialDark: true,
          fetchPage: (cursor) => cursor == null
              ? Future.value((
                  rows: [
                    for (var i = 0; i < 12; i++)
                      (title: 'Document $i', detail: 'PDF'),
                  ],
                  nextCursor: 'more',
                ))
              : pending.future,
        ),
      );
      await tester.pumpAndSettle();
      final scroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(_load, 180, scrollable: scroll);
      await Scrollable.ensureVisible(tester.element(_load), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(_load.hitTestable());
      await tester.pump();

      final position = tester.state<ScrollableState>(scroll).position;
      position.jumpTo(position.maxScrollExtent - 130);
      await tester.pump();
      final away = position.pixels;
      pending.completeError(StateError('page unavailable'));
      await tester.pumpAndSettle();
      expect(position.pixels, away);
      expect(find.bySemanticsLabel(_pageError), findsNothing);
      expect(_retry.hitTestable(), findsNothing);

      final error = find.text(_pageError);
      await tester.scrollUntilVisible(error, 100, scrollable: scroll);
      await tester.pumpAndSettle();
      final visible = tester.getSemantics(error);
      expect(visible.label, _pageError);
      expect(visible.flagsCollection.isLiveRegion, isTrue);
      expect(visible.flagsCollection.isHidden, isFalse);
      expect(_retry.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('first-page error waits until its text enters the viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _shortCollection(
        header: const SizedBox(height: 280),
        state: const CollectionPageFailure(message: 'Try again.', attempt: 1),
        onRequest: () {},
      ),
    );
    final title = find.text('First-page error');
    final viewport = tester.getRect(find.byType(CustomScrollView));
    expect(tester.getRect(title).top, greaterThanOrEqualTo(viewport.bottom));
    final label = find.bySemanticsLabel('First-page error\nTry again.');
    expect(label, findsNothing);

    await tester.ensureVisible(title);
    await tester.pump();
    expect(tester.getSemantics(label).flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('Retry stays reachable when the 200% footer cannot fit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 160);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var requests = 0;
    void request() => requests++;
    await tester.pumpWidget(
      _shortCollection(
        state: CollectionPageStatus.moreAvailable,
        hasRow: true,
        onRequest: request,
      ),
    );
    await tester.tap(_load.hitTestable());
    final message = List.filled(7, 'The next page could not load.').join(' ');
    await tester.pumpWidget(
      _shortCollection(
        state: CollectionPageFailure(message: message, attempt: 1),
        hasRow: true,
        onRequest: request,
      ),
    );
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(CustomScrollView));
    expect(
      tester.getSize(find.text(message)).height,
      greaterThan(viewport.height),
    );
    expect(_retry.hitTestable(), findsOneWidget);
    await tester.tap(_retry.hitTestable());
    expect(requests, 2);
  });

  for (final staleFailure in [false, true]) {
    testWidgets(
      'restart ignores stale page ${staleFailure ? 'failure' : 'success'}',
      (tester) async {
        final stale = Completer<CollectionDemoPage>();
        var firstRequests = 0;
        await tester.pumpWidget(
          CollectionBlockDemo(
            fetchPage: (cursor) async => cursor != null
                ? stale.future
                : ++firstRequests == 1
                ? _page('Old document', 'old-next')
                : _page('Current document'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(_load);
        await tester.tap(find.byTooltip('Skenario demo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Documents available').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('Current document'), findsOneWidget);
        expect(find.text('Old document'), findsNothing);

        if (staleFailure) {
          stale.completeError(StateError('old failure'));
        } else {
          stale.complete(_page('Late document', 'late-next'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Current document'), findsOneWidget);
        expect(find.text('Late document'), findsNothing);
        expect(_retry, findsNothing);
        expect(_load, findsNothing);
      },
    );
  }
}
