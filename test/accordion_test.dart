import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('mid-collapse retains Body and fades until exit', (tester) async {
    await tester.pumpWidget(
      host(
        const SingleChildScrollView(
          child: PaymentAccordionItem(
            title: 'Receipt',
            initiallyExpanded: true,
            child: SizedBox(height: 100, child: Text('Body')),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(find.text('Body'), findsOneWidget);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Body'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 75));
    await tester.pump(const Duration(microseconds: 1));
    expect(find.text('Body'), findsNothing);
  });
  testWidgets('re-tapping reverses collapse without a height jump', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SingleChildScrollView(
          child: PaymentAccordionItem(
            title: 'Receipt',
            initiallyExpanded: true,
            child: SizedBox(height: 100, child: Text('Body')),
          ),
        ),
        1,
      ),
    );
    final item = find
        .descendant(
          of: find.byType(PaymentAccordionItem),
          matching: find.byType(Column),
        )
        .first;
    final full = tester.getSize(item).height;
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    final middle = tester.getSize(item).height;
    expect(middle, lessThan(full));
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    expect(tester.getSize(item).height, closeTo(middle, 0.01));
    var previous = middle;
    for (var frame = 0; frame < 15; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Body'), findsOneWidget);
      final height = tester.getSize(item).height;
      expect(height, greaterThanOrEqualTo(previous));
      previous = height;
    }
    expect(previous, full);
  });
  testWidgets('collapsing content takes no taps', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentAccordionItem(
          title: 'Receipt',
          initiallyExpanded: true,
          child: GestureDetector(
            onTap: () => calls++,
            child: const SizedBox(height: 100, child: Text('Body')),
          ),
        ),
        1,
      ),
    );
    final point = tester.getCenter(find.text('Body'));
    await tester.tap(find.text('Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Body'), findsOneWidget);
    await tester.tapAt(point);
    expect(calls, 0);
    await tester.pumpAndSettle();
  });

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
