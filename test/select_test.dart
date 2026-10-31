import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/search_fold.dart';
import 'first_line_test.dart' show host;

void main() {
  test('fold diacritics for local choice filtering', () {
    expect(matchesQuery(foldForSearch('Ánh'), 'anh'), isTrue);
  });
  testWidgets('single selection reports value, closes and restores focus', (
    tester,
  ) async {
    String? result;
    final focus = FocusNode();
    await tester.pumpWidget(
      host(
        PaymentSelect<String>(
          label: 'Occupation',
          options: const [
            PaymentSelectOption(value: 'employee', label: 'Employee'),
            PaymentSelectOption(value: 'student', label: 'Student'),
          ],
          value: null,
          onChanged: (v) => result = v,
          focusNode: focus,
        ),
        1,
      ),
    );
    await tester.tap(find.text('Occupation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employee'));
    await tester.pumpAndSettle();
    expect(result, 'employee');
    expect(find.byType(PaymentSheet), findsNothing);
    expect(focus.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
  });
  testWidgets('multiple choices are staged until Apply', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(
      host(
        PaymentSelect<String>.multiple(
          label: 'Methods',
          options: const [
            PaymentSelectOption(value: 'a', label: 'Transfer'),
            PaymentSelectOption(value: 'b', label: 'QRIS'),
          ],
          values: {},
          onChanged: (v) => result = v,
        ),
        1,
      ),
    );
    await tester.tap(find.text('Methods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(result, {'a'});
  });
}
