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
}
