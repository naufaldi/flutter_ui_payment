import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
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

  for (final scale in [1.0, 2.0]) {
    testWidgets('search actions sit centred on the box at $scale', (
      tester,
    ) async {
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
      if (scale == 2) {
        // The label sits above the box and the button, not beside them.
        final label = tester.getRect(find.text('Search transactions'));
        expect(label.bottom, lessThanOrEqualTo(action.top));
      }
    });
  }
}
