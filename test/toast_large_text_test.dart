import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

void main() {
  late BuildContext context;
  Future<void> mount(WidgetTester tester, TextDirection direction) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(showCloseIcon: true),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: Directionality(textDirection: direction, child: child!),
        ),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  for (final direction in TextDirection.values) {
    testWidgets('B4: at 320 dp and 200% the person reads the whole toast and '
        'can tap Undo and close (${direction.name})', (tester) async {
      await mount(tester, direction);
      var undone = 0;
      final toast = showPaymentToast(
        context,
        message: 'Payment of 120 sent to Alex',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      final pill = tester.getRect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Material &&
                w.color == PaymentTheme.of(context).textPrimary,
          ),
        ),
      );
      final text = tester.getRect(find.text('Payment of 120 sent to Alex'));
      final action = tester.getRect(find.widgetWithText(TextButton, 'Undo'));
      final close = tester.getRect(
        find.byKey(StandardComponentType.closeButton.key),
      );
      final screen = Offset.zero & tester.view.physicalSize;
      for (final rect in [text, action, close]) {
        expect(pill.intersect(rect), rect, reason: '$rect inside $pill');
      }
      expect(screen.intersect(pill), pill);
      // The action sits on its own line under the message, on the end edge;
      // the close button stays in the top row.
      expect(action.top, greaterThanOrEqualTo(text.bottom));
      expect(close.top, lessThan(text.bottom));
      final ltr = direction == TextDirection.ltr;
      expect(
        ltr ? action.right : action.left,
        closeTo(ltr ? close.left : close.right, 13),
      );
      for (final target in [action, close]) {
        expect(target.width, greaterThanOrEqualTo(48));
        expect(target.height, greaterThanOrEqualTo(48));
      }

      await tester.tap(find.widgetWithText(TextButton, 'Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(undone, 1);
      await toast.closed;
    });
  }
}
