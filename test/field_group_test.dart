import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('disabled group and mixed optional labels', (tester) async {
    await tester.pumpWidget(
      host(
        const PaymentFormFieldGroup(
          legend: 'Identity',
          disabled: true,
          children: [
            PaymentTextField(label: 'Name', required: true),
            PaymentTextField(label: 'Place'),
          ],
        ),
        1,
      ),
    );
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((f) => f.enabled == false),
      isTrue,
    );
    expect(find.text('Place (optional)'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Identity')).flagsCollection.isHeader,
      isTrue,
    );
  });

  testWidgets('Month / Year stay side by side in a 329 dp phone card', (
    tester,
  ) async {
    Future<double> dy(double width, double scale) async {
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: width,
              child: const PaymentFormFieldGroup(
                legend: 'Card expiry',
                layout: Axis.horizontal,
                children: [
                  PaymentTextField(label: 'Month'),
                  PaymentTextField(label: 'Year'),
                ],
              ),
            ),
          ),
          scale,
        ),
      );
      return tester.getTopLeft(find.text('Year')).dy -
          tester.getTopLeft(find.text('Month')).dy;
    }

    expect(await dy(329, 1), 0);
    // Too narrow for two 140 dp fields, or at large text: stacked.
    expect(await dy(280, 1), greaterThan(0));
    expect(await dy(329, 2), greaterThan(0));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('legend → first control is one 16 dp gap at $scale (#66)', (
      tester,
    ) async {
      Future<double> gap(Widget first, Finder visibleTop) async {
        await tester.pumpWidget(
          host(
            Padding(
              padding: const EdgeInsets.all(16),
              child: PaymentFormFieldGroup(legend: 'Legend', children: [first]),
            ),
            scale,
          ),
        );
        return tester.getRect(visibleTop).top -
            tester.getRect(find.text('Legend')).bottom;
      }

      // A field's edge (at large text, its label above the box, #73) and a
      // selection row's label sit the same 16 dp below the legend; the
      // row's 48 dp target reaches into the gap but not onto the legend.
      expect(
        await gap(
          const PaymentTextField(label: 'Name'),
          scale == 1 ? find.byType(InputDecorator) : find.text('Name'),
        ),
        16,
      );
      var toggled = false;
      expect(
        await gap(
          PaymentSwitch(
            label: 'Refunds',
            value: false,
            onChanged: (v) => toggled = v,
          ),
          find.text('Refunds'),
        ),
        16,
      );
      final row = tester.getRect(find.byType(InkWell));
      expect(row.height, greaterThanOrEqualTo(48));
      // The target never covers the legend, and its strip above the label
      // still takes the tap.
      expect(
        row.top,
        greaterThanOrEqualTo(tester.getRect(find.text('Legend')).bottom),
      );
      await tester.tapAt(Offset(row.center.dx, row.top + 1));
      expect(toggled, isTrue);
      // The legend still comes before the row.
      final order = tester.semantics.simulatedAccessibilityTraversal().toList();
      final legendAt = order.indexWhere((n) => n.label == 'Legend');
      expect(legendAt, isNonNegative);
      expect(
        legendAt,
        lessThan(order.indexWhere((n) => n.label.contains('Refunds'))),
      );
      expect(
        await gap(
          PaymentRadio<int>(
            label: 'Bank',
            value: 0,
            groupValue: 0,
            onChanged: (_) {},
          ),
          find.text('Bank'),
        ),
        16,
      );
      expect(
        await gap(
          PaymentCheckbox(
            label: 'Save card',
            description: 'For next time',
            value: false,
            onChanged: (_) {},
          ),
          find.text('Save card'),
        ),
        16,
      );
    });
  }
}
