import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/date_input.dart';
import 'first_line_test.dart' show host;

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
}
