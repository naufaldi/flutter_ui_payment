import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('actions do not toggle; header controls its content', (
    tester,
  ) async {
    var edits = 0;
    final toggles = <bool>[];
    await tester.pumpWidget(
      host(
        PaymentAccordion(
          children: [
            PaymentAccordionItem(
              title: 'Receipt',
              onExpandedChanged: toggles.add,
              actions: [
                PaymentButton(
                  label: 'Edit',
                  size: PaymentSize.small,
                  width: PaymentWidth.hug,
                  variant: PaymentButtonVariant.secondary,
                  onPressed: () => edits++,
                ),
              ],
              child: const Text('Body'),
            ),
          ],
        ),
        1,
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(toggles, isEmpty);
    expect(find.text('Body'), findsNothing);
    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();
    expect(toggles, [true]);
    expect(find.text('Body'), findsOneWidget);
    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });
  testWidgets('controlled state stays host-owned and initial state works', (
    tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      host(
        PaymentAccordionItem(
          title: 'Controlled',
          expanded: false,
          onExpandedChanged: changes.add,
          child: const Text('Body'),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Controlled'));
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(find.text('Body'), findsNothing);
    await tester.pumpWidget(
      host(
        const PaymentAccordionItem(
          key: ValueKey('new'),
          title: 'Initial',
          initiallyExpanded: true,
          child: Text('Body'),
        ),
        1,
      ),
    );
    expect(find.text('Body'), findsOneWidget);
  });
  testWidgets('unsupported actions assert', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentAccordionItem(
          title: 'Receipt',
          actions: [PaymentButton(label: 'Edit', onPressed: () {})],
          child: const Text('Body'),
        ),
        1,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
}
