import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('multiline, counter and modified Enter submission', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      host(
        PaymentTextArea(
          label: 'Description',
          maxLength: 20,
          onSubmitted: (v) => submitted = v,
        ),
        1,
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'a\nb');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).keyboardType,
      TextInputType.multiline,
    );
    expect(find.text('3/20'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(submitted, 'a\nb');
  });
}
