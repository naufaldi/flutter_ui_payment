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
}
