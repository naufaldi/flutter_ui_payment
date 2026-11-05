import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'first_line_test.dart' show host;

final _preset = PaymentDatePreset(
  label: 'Last 30 days',
  start: DateTime(2026, 10, 2),
  end: DateTime(2026, 10, 31),
);

Widget _button(
  PaymentDateRange? value,
  ValueChanged<PaymentDateRange?> onChanged,
) => PaymentDateRangePicker.button(
  key: const Key('range'),
  label: 'Date range',
  value: value,
  onChanged: onChanged,
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
  presets: [_preset],
);

void main() {
  testWidgets('range button opens the presets and reads selected (D63a)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    PaymentDateRange? value;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) =>
              _button(value, (v) => setState(() => value = v)),
        ),
        1,
      ),
    );
    final button = find.byKey(const Key('range'));
    var node = tester.getSemantics(button).getSemanticsData();
    expect(node.tooltip, 'Date range');
    expect(node.flagsCollection.isSelected, isNot(Tristate.isTrue));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    expect(value, PaymentDateRange.fromPreset(_preset));
    node = tester.getSemantics(button).getSemanticsData();
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(node.value, startsWith('Last 30 days · '));
    expect(find.byIcon(Icons.date_range), findsOneWidget);
    // Clearing from the presets sheet reports null.
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear dates'));
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(find.byIcon(Icons.date_range_outlined), findsOneWidget);
    handle.dispose();
  });

  testWidgets('on a 320 dp phone at 200% the status filter is a button on the '
      'search line (D91)', (tester) async {
    tester.view.physicalSize = const Size(320, 569);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    var filter = TransactionFilter.all;
    Widget history(double scale) => host(
      StatefulBuilder(
        builder: (context, setState) => TransactionHistory(
          records: const [],
          query: '',
          filter: filter,
          onQueryChanged: (_) {},
          onFilterChanged: (f) => setState(() => filter = f),
          onOpen: (_) {},
          searchActions: [_button(null, (_) {})],
        ),
      ),
      scale,
    );
    // Normal text keeps the tabs.
    await tester.pumpWidget(history(1));
    expect(find.byType(PaymentTabs), findsOneWidget);
    await tester.pumpWidget(history(2));
    expect(find.byType(PaymentTabs), findsNothing);
    final button = find.byKey(const ValueKey('transaction-status-filter'));
    final box = tester.getRect(find.byType(InputDecorator));
    final rect = tester.getRect(button);
    expect(rect.center.dy, moreOrLessEquals(box.center.dy, epsilon: 0.5));
    expect(rect.left, greaterThanOrEqualTo(box.right));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
    var node = tester.getSemantics(button).getSemanticsData();
    expect(node.tooltip, 'Filter by status');
    expect(node.value, 'All');
    // The person picks a status from the sheet; the button then reads it.
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refunds'));
    await tester.pumpAndSettle();
    expect(filter, TransactionFilter.refunds);
    node = tester.getSemantics(button).getSemanticsData();
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(node.value, 'Refunds');
    handle.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('search actions sit centred on the box at $scale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          TransactionHistory(
            records: const [],
            query: '',
            filter: TransactionFilter.all,
            onQueryChanged: (_) {},
            onFilterChanged: (_) {},
            onOpen: (_) {},
            searchActions: [_button(null, (_) {})],
          ),
          scale,
        ),
      );
      final box = tester.getRect(find.byType(InputDecorator));
      final action = tester.getRect(find.byKey(const Key('range')));
      expect(action.center.dy, moreOrLessEquals(box.center.dy, epsilon: 0.5));
      expect(action.left, greaterThanOrEqualTo(box.right));
      expect(action.height, greaterThanOrEqualTo(48));
      // With actions the label is the placeholder inside the box at every
      // size, and still the field's spoken name (D63a).
      final placeholder = tester.getRect(find.text('Search transactions'));
      expect(box.contains(placeholder.center), isTrue);
      // Exactly once: a placeholder that isn't excluded from semantics
      // would be read after the label.
      expect(
        tester.getSemantics(find.byType(EditableText)).getSemanticsData().label,
        'Search transactions',
      );
      handle.dispose();
    });
  }
}
