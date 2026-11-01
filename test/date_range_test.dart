import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ui_payment/src/forms/calendar/month_grid.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;
import 'dialog_test.dart' show app, compact, surface;
import 'date_field_test.dart' show day;

Finder get apply => find.widgetWithText(PaymentButton, 'Apply');

/// October 2020 only, so the sheet opens on it whatever today is.
Widget picker({
  PaymentDateRange? value,
  required ValueChanged<PaymentDateRange?> onChanged,
  DateTime? last,
  Locale locale = const Locale('en'),
  double scale = 1,
}) => app(
  PaymentDateRangePicker(
    label: 'Range',
    value: value,
    onChanged: onChanged,
    firstDate: DateTime(2020, 10),
    lastDate: last ?? DateTime(2020, 10, 31),
  ),
  locale: locale,
  scale: scale,
);

void main() {
  test('localized compact ranges and value equality', () {
    final en = PaymentLocalizations('en'), id = PaymentLocalizations('id');
    expect(
      en.formatDateRange(DateTime(2026, 10), DateTime(2026, 10, 31)),
      '1\u2060–\u206031\u00A0Oct\u00A02026',
    );
    expect(
      id.formatDateRange(DateTime(2026, 10), DateTime(2026, 10, 31)),
      '1\u2060–\u206031\u00A0Okt\u00A02026',
    );
    expect(
      en.formatDateRange(DateTime(2026, 9, 28), DateTime(2026, 10, 3)),
      '28\u00A0Sep\u00A0– 3\u00A0Oct\u00A02026',
    );
    expect(
      en.formatDateRange(DateTime(2025, 12, 30), DateTime(2026, 1, 2)),
      '30\u00A0Dec\u00A02025\u00A0– 2\u00A0Jan\u00A02026',
    );
    final p = PaymentDatePreset(
      label: 'This month',
      start: DateTime(2026, 10),
      end: DateTime(2026, 10, 31),
    );
    expect(PaymentDateRange.fromPreset(p), PaymentDateRange.fromPreset(p));
  });
  testWidgets('preset selection and clearing report host changes', (
    tester,
  ) async {
    PaymentDateRange? result;
    final p = PaymentDatePreset(
      label: 'Last 30 days',
      start: DateTime(2026, 10, 2),
      end: DateTime(2026, 10, 31),
    );
    await tester.pumpWidget(
      host(
        PaymentDateRangePicker(
          label: 'Range',
          value: null,
          onChanged: (v) => result = v,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          presets: [p],
        ),
        1,
      ),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    expect(result, PaymentDateRange.fromPreset(p));
  });

  group('kit range sheet (D51)', () {
    testWidgets('two taps and Apply report a range; no Material picker', (
      tester,
    ) async {
      surface(tester, compact);
      final reports = <PaymentDateRange?>[];
      await tester.pumpWidget(picker(onChanged: reports.add));
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsNothing);
      // Full height with Apply pinned at the bottom.
      expect(tester.getSize(find.byType(BottomSheet)).height, compact.height);
      expect(tester.widget<PaymentButton>(apply).onPressed, isNull);
      await tester.tap(day('Monday, 5 October 2020'));
      await tester.pump();
      expect(find.text('Choose an end date'), findsNothing); // in a span
      expect(
        find.textContaining('Choose an end date', findRichText: true),
        findsOneWidget,
      );
      final start = tester.getSemantics(day('Monday, 5 October 2020'));
      expect(start.label, contains('range start'));
      expect(start.flagsCollection.isSelected, Tristate.isTrue);
      await tester.tap(day('Monday, 12 October 2020'));
      await tester.pump();
      expect(
        tester.getSemantics(day('Monday, 12 October 2020')).label,
        contains('range end'),
      );
      final l = PaymentLocalizations('en');
      expect(
        find.text(
          l.formatDateRange(DateTime(2020, 10, 5), DateTime(2020, 10, 12)),
        ),
        findsOneWidget,
      );
      expect(tester.getRect(apply).bottom, lessThanOrEqualTo(compact.height));
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(reports, [
        PaymentDateRange(
          start: DateTime(2020, 10, 5),
          end: DateTime(2020, 10, 12),
        ),
      ]);
    });

    testWidgets('a tap before the start restarts; start only is one day', (
      tester,
    ) async {
      surface(tester, compact);
      PaymentDateRange? result;
      await tester.pumpWidget(picker(onChanged: (v) => result = v));
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      await tester.tap(day('Monday, 12 October 2020'));
      await tester.tap(day('Monday, 5 October 2020'));
      await tester.pump();
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(
        result,
        PaymentDateRange(
          start: DateTime(2020, 10, 5),
          end: DateTime(2020, 10, 5),
        ),
      );
    });

    testWidgets('days after lastDate are disabled', (tester) async {
      surface(tester, compact);
      PaymentDateRange? result;
      await tester.pumpWidget(
        picker(onChanged: (v) => result = v, last: DateTime(2020, 10, 20)),
      );
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      final late = day('Sunday, 25 October 2020');
      expect(
        tester.getSemantics(late).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      await tester.tap(late);
      await tester.pump();
      expect(tester.widget<PaymentButton>(apply).onPressed, isNull);
      expect(result, isNull);
    });

    testWidgets('Clear reports no range', (tester) async {
      surface(tester, compact);
      final reports = <PaymentDateRange?>[];
      await tester.pumpWidget(
        picker(
          value: PaymentDateRange(
            start: DateTime(2020, 10, 5),
            end: DateTime(2020, 10, 12),
          ),
          onChanged: reports.add,
        ),
      );
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PaymentButton, 'Clear'));
      await tester.pumpAndSettle();
      expect(reports, [null]);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('typed entry reports a range and flags a reversed one', (
      tester,
    ) async {
      surface(tester, compact);
      PaymentDateRange? result;
      await tester.pumpWidget(picker(onChanged: (v) => result = v));
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Type dates'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(EditableText),
      );
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, '20102020');
      await tester.enterText(fields.last, '10102020');
      await tester.pump();
      expect(
        find.text('The start date must be on or before the end date.'),
        findsOneWidget,
      );
      expect(tester.widget<PaymentButton>(apply).onPressed, isNull);
      await tester.enterText(fields.last, '25102020');
      await tester.pump();
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(
        result,
        PaymentDateRange(
          start: DateTime(2020, 10, 20),
          end: DateTime(2020, 10, 25),
        ),
      );
    });

    testWidgets('Indonesian weeks start on Monday; English on Sunday', (
      tester,
    ) async {
      surface(tester, compact);
      for (final (locale, first) in [('id', 'Sen'), ('en', 'Sun')]) {
        await tester.pumpWidget(
          picker(onChanged: (_) {}, locale: Locale(locale)),
        );
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        final header = find.byType(WeekdayHeader);
        final labels = tester
            .widgetList<Text>(
              find.descendant(of: header, matching: find.byType(Text)),
            )
            .map((t) => t.data)
            .toList();
        expect(labels.first, first);
        // Oct 2020 starts on a Thursday: 3 blanks in id, 4 in en.
        final dayOne = tester.getTopLeft(
          day(
            locale == 'id'
                ? 'Kamis, 1 Oktober 2020'
                : 'Thursday, 1 October 2020',
          ),
        );
        final colWidth = tester.getSize(header).width / 7;
        final column = ((dayOne.dx - tester.getTopLeft(header).dx) / colWidth)
            .floor();
        expect(column, locale == 'id' ? 3 : 4);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('2x: the range sheet keeps its footer on screen', (
      tester,
    ) async {
      surface(tester, compact);
      await tester.pumpWidget(picker(onChanged: (_) {}, scale: 2));
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(apply).bottom, lessThanOrEqualTo(compact.height));
    });

    testWidgets('Custom range sits on the presets text column', (tester) async {
      surface(tester, compact);
      await tester.pumpWidget(
        app(
          PaymentDateRangePicker(
            label: 'Range',
            value: null,
            onChanged: (_) {},
            firstDate: DateTime(2020),
            lastDate: DateTime(2020, 12, 31),
            presets: [
              PaymentDatePreset(
                label: 'Last 7 days',
                start: DateTime(2020, 10, 25),
                end: DateTime(2020, 10, 31),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Custom range')).dx,
        tester.getTopLeft(find.text('Last 7 days')).dx,
      );
      await tester.tap(find.text('Custom range'));
      await tester.pumpAndSettle();
      expect(find.text('Type dates'), findsOneWidget);
    });

    testWidgets('arrow keys move by a day and a week; Enter picks', (
      tester,
    ) async {
      surface(tester, compact);
      await tester.pumpWidget(picker(onChanged: (_) {}));
      await tester.tap(find.text('Range'));
      await tester.pumpAndSettle();
      Focus.of(
        tester.element(
          find.descendant(of: find.byType(MonthGrid), matching: find.text('5')),
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(day('Tuesday, 13 October 2020')).label,
        contains('range start'),
      );
    });
  });
}
