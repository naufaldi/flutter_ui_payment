import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_ui_payment/src/foundation/date_input.dart';
import 'package:flutter_ui_payment/src/forms/calendar/month_grid.dart';
import 'first_line_test.dart' show host;
import 'dialog_test.dart' show app, compact, surface;

/// A calendar day by its spoken label; no-break spaces join the date.
Finder day(String label) =>
    find.bySemanticsLabel(RegExp('^${label.replaceAll(' ', r'\s')}(,|\$)'));

Widget field({
  required DateTime first,
  required DateTime last,
  DateTime? value,
  required ValueChanged<DateTime?> onChanged,
  double scale = 1,
}) => app(
  PaymentDateField(
    label: 'Date',
    value: value,
    onChanged: onChanged,
    firstDate: first,
    lastDate: last,
  ),
  scale: scale,
);

Finder get chooseButton => find.widgetWithText(PaymentButton, 'Choose date');

void main() {
  test('date parsing rejects invalid dates and supports token order', () {
    expect(parseDateInput('31/02/2000', 'DD/MM/YYYY'), isNull);
    expect(parseDateInput('17-08-1995', 'DD/MM/YYYY'), DateTime(1995, 8, 17));
    expect(parseDateInput('08/17/1995', 'MM/DD/YYYY'), DateTime(1995, 8, 17));
    expect(formatDateInput(DateTime(1995, 8, 17), 'DD/MM/YYYY'), '17/08/1995');
    expect(parseIsoDate('1995-08-17'), DateTime(1995, 8, 17));
    expect(parseIsoDate('2000-02-31'), isNull);
    expect(PaymentLocalizations('id').dateInputHint, 'HH/BB/TTTT');
  });
  testWidgets(
    'typed date inserts separators, reports real date, validates on blur',
    (tester) async {
      DateTime? value;
      final focus = FocusNode();
      await tester.pumpWidget(
        host(
          PaymentDateField(
            label: 'Date of birth',
            value: null,
            onChanged: (d) => value = d,
            firstDate: DateTime(1900),
            lastDate: DateTime(2030),
            focusNode: focus,
          ),
          1,
        ),
      );
      await tester.enterText(find.byType(TextFormField), '1708');
      expect(find.text('Enter a valid date'), findsNothing);
      focus.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid date'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '17081995');
      await tester.pumpAndSettle();
      expect(value, DateTime(1995, 8, 17));
      expect(find.text('17/08/1995'), findsOneWidget);
      expect(find.text('Enter a valid date'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );

  group('kit date sheet (D52, D52a)', () {
    testWidgets('near dates: calendar pick reports a value', (tester) async {
      surface(tester, compact);
      DateTime? value;
      await tester.pumpWidget(
        field(
          // One month away from today, so the sheet opens on it.
          first: DateTime(2020, 10, 10),
          last: DateTime(2020, 10, 31),
          onChanged: (d) => value = d,
        ),
      );
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byType(ListWheelScrollView), findsNothing);
      expect(find.text('October\u00A02020'), findsOneWidget);
      // Before firstDate: disabled, so nothing is chosen.
      await tester.tap(day('Monday, 5 October 2020'));
      await tester.pump();
      expect(tester.widget<PaymentButton>(chooseButton).onPressed, isNull);
      await tester.tap(day('Tuesday, 20 October 2020'));
      await tester.pump();
      expect(
        tester
            .getSemantics(day('Tuesday, 20 October 2020'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();
      expect(value, DateTime(2020, 10, 20));
      expect(find.text('20/10/2020'), findsOneWidget);
    });

    testWidgets('far dates: an empty wheel opens at lastDate; year steps', (
      tester,
    ) async {
      surface(tester, compact);
      DateTime? value;
      await tester.pumpWidget(
        field(
          first: DateTime(1900),
          last: DateTime(2008, 11, 1),
          onChanged: (d) => value = d,
        ),
      );
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));
      expect(find.byType(MonthGrid), findsNothing);
      // Screen-reader adjust on the year column, three years back.
      final year = find.bySemanticsLabel('Year');
      expect(tester.getSemantics(year).value, '2008');
      for (var i = 0; i < 3; i++) {
        final node = tester.getSemantics(year);
        tester.binding.pipelineOwner.semanticsOwner!.performAction(
          node.id,
          SemanticsAction.decrease,
        );
        await tester.pumpAndSettle();
      }
      expect(tester.getSemantics(year).value, '2005');
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();
      expect(value, DateTime(2005, 11, 1));
    });

    testWidgets('the wheel settles back inside the range', (tester) async {
      surface(tester, compact);
      DateTime? value;
      await tester.pumpWidget(
        field(
          first: DateTime(1900),
          last: DateTime(2008, 3, 15),
          value: DateTime(2007, 12, 31),
          onChanged: (d) => value = d,
        ),
      );
      await tester.tap(find.byTooltip('Choose date'));
      await tester.pumpAndSettle();
      final year = find.bySemanticsLabel('Year');
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        tester.getSemantics(year).id,
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();
      // 31 Dec 2008 is after lastDate, so the wheel lands on lastDate.
      expect(value, DateTime(2008, 3, 15));
    });

    for (final wheel in [true, false]) {
      testWidgets('2x: the ${wheel ? 'wheel' : 'calendar'} sheet fits', (
        tester,
      ) async {
        surface(tester, compact);
        await tester.pumpWidget(
          field(
            first: wheel ? DateTime(1900) : DateTime(2026, 9),
            last: DateTime(2026, 11, 30),
            value: DateTime(2026, 9, 23),
            onChanged: (_) {},
            scale: 2,
          ),
        );
        await tester.tap(find.byTooltip('Choose date'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(chooseButton, findsOneWidget);
        // The footer action stays on screen.
        expect(
          tester.getRect(chooseButton).bottom,
          lessThanOrEqualTo(compact.height),
        );
      });
    }
  });
}
