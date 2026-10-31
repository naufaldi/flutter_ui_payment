import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  testWidgets('phone selection is labeled and sorting can restore host order', (
    t,
  ) async {
    await setSurface(t, const Size(360, 1000));
    var selected = <String>{};
    PaymentDataSort? changed;
    await t.pumpWidget(
      contentHost(
        StatefulBuilder(
          builder: (context, update) => PaymentDataTable<int>(
            columns: [
              PaymentDataColumn<int>(
                key: 'amount',
                label: 'Amount',
                value: (r) => Money.idr(r),
                cell: PaymentCellType.currency,
                sortable: true,
              ),
            ],
            rows: const [2, 1],
            rowKey: (r) => '$r',
            selection: selected,
            onSelectionChanged: (v) => update(() => selected = v),
            onSortChanged: (v) => changed = v,
          ),
        ),
      ),
    );
    expect(find.text('Select all on this page'), findsOneWidget);
    await t.tap(find.text('Select all on this page'));
    await t.pumpAndSettle();
    expect(selected, {'1', '2'});
    expect(find.text('2 selected'), findsOneWidget);
    expect(
      t.getTopLeft(find.widgetWithText(PaymentButton, 'Sort')).dx,
      t.getTopLeft(find.byType(PaymentDataTable<int>)).dx,
    );
    await t.tap(find.text('Sort'));
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text('Amount, highest first'),
      ),
    );
    await t.pumpAndSettle();
    expect(changed?.ascending, isFalse);
    expect(find.text('Sort: Amount, highest first'), findsOneWidget);
    await t.tap(find.text('Sort: Amount, highest first'));
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text('Default order'),
      ),
    );
    await t.pumpAndSettle();
    expect(changed, isNull);
    expect(find.text('Sort'), findsOneWidget);
  });

  testWidgets('hidden heading retains spoken label and sort action', (t) async {
    await setSurface(t, const Size(800, 1000));
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      contentHost(
        PaymentDataTable<int>(
          columns: [
            PaymentDataColumn<int>(
              key: 'reference',
              label: 'Reference',
              value: (r) => r,
              hideHeaderLabel: true,
              sortable: true,
            ),
          ],
          rows: const [2, 1],
          rowKey: (r) => '$r',
        ),
      ),
    );
    expect(find.text('Reference'), findsNothing);
    expect(find.bySemanticsLabel('Reference'), findsWidgets);
    expect(t.takeException(), isNull);
    semantics.dispose();
  });

  final columns = [
    PaymentDataColumn<int>(
      key: 'name',
      label: 'Reference',
      pinned: true,
      value: (r) => 'STL-$r',
    ),
    PaymentDataColumn<int>(
      key: 'amount',
      label: 'Amount',
      value: (r) => Money.idr(r),
      cell: PaymentCellType.currency,
      sortable: true,
    ),
  ];
  testWidgets('local paging displays only this page and calls host', (t) async {
    await setSurface(t, const Size(1024, 2000));
    var changed = 0;
    await t.pumpWidget(
      contentHost(
        PaymentDataTable<int>(
          columns: columns,
          rows: List.generate(1000, (i) => i + 1),
          rowKey: (r) => '$r',
          pagination: PaymentPagination.local(
            pageSize: 25,
            onPageChanged: (p) => changed = p,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('STL-25'), findsOneWidget);
    expect(find.text('STL-26'), findsNothing);
    expect(find.text('1–25 of 1000'), findsOneWidget);
    await t.ensureVisible(find.byTooltip('Next page'));
    await t.tap(find.byTooltip('Next page'));
    await t.pumpAndSettle();
    expect(changed, 2);
    expect(find.text('STL-26'), findsOneWidget);
    expect(find.text('26–50 of 1000'), findsOneWidget);
  });
  testWidgets('local sort cycles; offset preserves supplied rows', (t) async {
    await setSurface(t, const Size(1024, 1000));
    PaymentDataSort? sort;
    Widget table(PaymentPagination? p) => contentHost(
      PaymentDataTable<int>(
        key: ValueKey(p?.page),
        columns: columns,
        rows: const [3, 1, 2],
        rowKey: (r) => '$r',
        pagination: p,
        onSortChanged: (s) => sort = s,
      ),
    );
    await t.pumpWidget(table(null));
    await t.pumpAndSettle();
    await t.tap(find.text('Amount'));
    await t.pumpAndSettle();
    expect(sort?.ascending, true);
    expect(
      t.getTopLeft(find.text('STL-1')).dy,
      lessThan(t.getTopLeft(find.text('STL-3')).dy),
    );
    await t.tap(find.text('Amount'));
    await t.pumpAndSettle();
    expect(sort?.ascending, false);
    await t.tap(find.text('Amount'));
    await t.pumpAndSettle();
    expect(sort, isNull);
    expect(
      t.getTopLeft(find.text('STL-3')).dy,
      lessThan(t.getTopLeft(find.text('STL-1')).dy),
    );
    await t.pumpWidget(
      table(
        PaymentPagination.offset(
          page: 2,
          pageSize: 25,
          totalItems: 100,
          onPageChanged: (_) {},
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Amount'));
    await t.pumpAndSettle();
    expect(
      t.getTopLeft(find.text('STL-3')).dy,
      lessThan(t.getTopLeft(find.text('STL-1')).dy),
    );
  });
  testWidgets('cursor reports pages without slicing supplied rows', (t) async {
    var requested = 0;
    await t.pumpWidget(
      contentHost(
        PaymentDataTable<int>(
          columns: columns,
          rows: const [1, 2, 3],
          rowKey: (r) => '$r',
          pagination: PaymentPagination.cursor(
            page: 2,
            pageSize: 1,
            hasMore: false,
            onPageChanged: (p) => requested = p,
          ),
        ),
      ),
    );
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('STL-3'), findsOneWidget);
    await t.tap(find.byTooltip('Previous page'));
    await t.pumpAndSettle();
    expect(requested, 1);
    final next = t.widget<PaymentIconButton>(
      find.byWidgetPredicate(
        (w) => w is PaymentIconButton && w.tooltip == 'Next page',
      ),
    );
    expect(next.onPressed, isNull);
  });
  test('status columns require semantic tones', () {
    expect(
      () => PaymentDataColumn<int>(
        key: 'status',
        label: 'Status',
        value: (r) => r,
        cell: PaymentCellType.status,
      ),
      throwsAssertionError,
    );
  });
  testWidgets('host filter and no matches', (t) async {
    Widget table(String query) => contentHost(
      PaymentDataTable<int>(
        columns: columns,
        rows: const [1, 2, 3],
        rowKey: (r) => '$r',
        filter: (r, q) => r.toString().contains(q),
        filterQuery: query,
      ),
    );
    await t.pumpWidget(table('2'));
    expect(find.text('STL-2'), findsOneWidget);
    expect(find.text('STL-1'), findsNothing);
    await t.pumpWidget(table('missing'));
    expect(find.text('No matches'), findsOneWidget);
  });
  testWidgets('select all applies to the page and keeps off-page keys', (
    t,
  ) async {
    Set<String> selected = {'other', '1'};
    await t.pumpWidget(
      contentHost(
        StatefulBuilder(
          builder: (context, set) => PaymentDataTable<int>(
            columns: columns,
            rows: const [1, 2, 3],
            rowKey: (r) => '$r',
            pagination: const PaymentPagination.local(pageSize: 2),
            selection: selected,
            onSelectionChanged: (s) => set(() => selected = s),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final all = find.byWidgetPredicate(
      (w) => w is PaymentCheckbox && w.label == 'Select all on this page',
    );
    expect(t.widget<PaymentCheckbox>(all).indeterminate, true);
    await t.tap(all);
    await t.pumpAndSettle();
    expect(selected, {'other', '1', '2'});
  });
  testWidgets('row actions and press call host; narrow large text is safe', (
    t,
  ) async {
    await setSurface(t, const Size(320, 1200));
    var pressed = 0;
    var action = 0;
    for (final dark in [false, true]) {
      await t.pumpWidget(
        contentHost(
          PaymentDataTable<int>(
            columns: columns,
            rows: const [1],
            rowKey: (r) => '$r',
            onRowPressed: (r) => pressed = r,
            rowActions: [
              PaymentRowAction<int>(
                id: 'view',
                label: 'View receipt',
                onPressed: (r) => action = r,
              ),
              PaymentRowAction<int>(
                id: 'delete',
                label: 'Delete',
                destructive: true,
                onPressed: (_) {},
              ),
            ],
          ),
          scale: 2,
          dark: dark,
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    await t.tap(find.text('STL-1'));
    await t.pumpAndSettle();
    expect(pressed, 1);
    await t.tap(find.byTooltip('Actions for STL-1'));
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text('View receipt'),
      ),
    );
    await t.pumpAndSettle();
    expect(action, 1);
  });
  testWidgets('loading, empty action and retry', (t) async {
    var called = 0;
    Widget table({
      bool pending = false,
      String? error,
      PaymentEmptyMessage? empty,
    }) => contentHost(
      PaymentDataTable<int>(
        columns: columns,
        rows: const [],
        rowKey: (r) => '$r',
        pending: pending,
        errorText: error,
        onRetry: () => called++,
        emptyMessage: empty,
      ),
    );
    await t.pumpWidget(table(pending: true));
    expect(find.byType(LoadingSkeleton), findsWidgets);
    await t.pumpWidget(
      table(
        empty: PaymentEmptyMessage(
          'No settlements yet',
          actionLabel: 'Create',
          onAction: () => called++,
        ),
      ),
    );
    await t.tap(find.text('Create'));
    await t.pump();
    expect(called, 1);
    await t.pumpWidget(table(error: 'Failed'));
    expect(
      t.widget<StateMessage>(find.byType(StateMessage)).tone,
      StatusTone.danger,
    );
    await t.tap(find.text('Retry'));
    await t.pump();
    expect(called, 2);
  });
}
