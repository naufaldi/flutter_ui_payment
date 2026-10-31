import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  for (final (currency, initial, pad, expected) in [
    ('USD', '5', true, '5.00'),
    ('USD', '5.5', true, '5.50'),
    ('USD', '5.25', true, '5.25'),
    ('IDR', '5', true, '5'),
    ('USD', 'bad', true, 'bad'),
    ('USD', '5', false, '5'),
  ]) {
    testWidgets('pad $currency $initial $pad', (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              PaymentCurrencyField(
                currency: currency,
                initialText: initial,
                padFractionDigits: pad,
                onChanged: (_) => changes++,
              ),
              TextButton(onPressed: () {}, child: const Text('Next')),
            ],
          ),
          1,
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      tester.widget<TextField>(find.byType(TextField)).focusNode!.unfocus();
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        expected,
      );
      expect(changes, 0);
    });
  }
  testWidgets('size steps and description before limits', (tester) async {
    final heights = <double>[];
    for (final size in PaymentSize.values) {
      await tester.pumpWidget(
        host(
          PaymentCurrencyField(
            currency: 'IDR',
            size: size,
            onChanged: (_) {},
            description: 'Use your available balance',
            minimum: const Money.idr(10000),
          ),
          1,
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      final box = tester.getSize(find.byType(InputDecorator));
      heights.add(box.height);
      debugPrint('Currency size $size height=${box.height}');
      expect(
        field.style,
        PaymentType.of(tester.element(find.byType(TextField))).amountLarge,
      );
      expect(
        field.decoration!.helperText,
        startsWith('Use your available balance\n'),
      );
    }
    expect(heights[1] - heights[0], 8);
    expect(heights[2] - heights[1], 8);
    expect(heights[0], greaterThanOrEqualTo(48));
  });
}
