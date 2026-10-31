import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'button_guard_test.dart' show host;

void main() {
  for (final destructive in [false, true]) {
    for (final action in ['Confirm', 'Cancel', 'barrier', 'Escape', 'Enter']) {
      testWidgets('$destructive $action', (tester) async {
        tester.view.physicalSize = const Size(393, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        bool? result;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showPaymentConfirmDialog(
                    context,
                    title: 'Remove card?',
                    message: 'You can add it again later.',
                    confirmLabel: 'Confirm',
                    destructive: destructive,
                  );
                },
                child: const Text('Open'),
              ),
            ),
            1,
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final buttons = find.byType(PaymentButton);
        expect(buttons, findsNWidgets(2));
        for (final e in buttons.evaluate()) {
          expect(
            tester.getSize(find.byWidget(e.widget)).width,
            greaterThanOrEqualTo(112),
          );
        }
        expect(
          tester.getTopLeft(buttons.first).dy,
          tester.getTopLeft(buttons.last).dy,
        );
        final focusLabel = destructive ? 'Cancel' : 'Confirm';
        expect(
          Focus.of(tester.element(find.text(focusLabel))).hasFocus,
          isTrue,
        );
        switch (action) {
          case 'barrier':
            await tester.tapAt(const Offset(4, 4));
          case 'Escape':
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          case 'Enter':
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          default:
            await tester.tap(find.text(action));
        }
        await tester.pumpAndSettle();
        expect(
          result,
          action == 'Confirm' || (action == 'Enter' && !destructive),
        );
      });
    }
  }
  testWidgets(
    'dialog stacks confirm above cancel with spacing at 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPaymentConfirmDialog(
                context,
                title: 'Remove card?',
                message: 'You can add it again later.',
                confirmLabel: 'Remove card',
                destructive: true,
              ),
              child: const Text('Open'),
            ),
          ),
          2,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final confirm = tester.getRect(
        find.widgetWithText(PaymentButton, 'Remove card'),
      );
      final cancel = tester.getRect(
        find.widgetWithText(PaymentButton, 'Cancel'),
      );
      expect(cancel.top - confirm.bottom, greaterThanOrEqualTo(8));
      expect(tester.takeException(), isNull);
    },
  );
}
