import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment/src/foundation/search_fold.dart';
import 'first_line_test.dart' show host;

void main() {
  test('local filter correctness over 1000 values', () {
    expect(
      List.generate(
        1000,
        (i) => 'Item $i',
      ).where((s) => matchesQuery(foldForSearch(s), 'Item 99')).length,
      11,
    );
  });
  testWidgets('filter, live count and keyboard selection', (tester) async {
    String? picked;
    await tester.pumpWidget(
      host(
        PaymentSearchField<String>(
          label: 'Province',
          options: const [
            PaymentSearchOption(value: 'aceh', label: 'Áceh'),
            PaymentSearchOption(value: 'barat', label: 'Jawa Barat'),
            PaymentSearchOption(value: 'timur', label: 'Jawa Timur'),
          ],
          selected: null,
          onSelected: (v) => picked = v,
        ),
        1,
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'jawa');
    await tester.pumpAndSettle();
    expect(find.text('Áceh'), findsNothing);
    expect(find.bySemanticsLabel('2 results'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, 'timur');
    expect(find.text('Jawa Timur'), findsOneWidget);
  });
}
