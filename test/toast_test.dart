import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  late PaymentToastController controller;
  Future<void> show(
    WidgetTester tester, {
    String message = 'Copied',
    bool pending = false,
    bool action = false,
    bool accessible = false,
    VoidCallback? onAction,
  }) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => controller = showPaymentToast(
              context,
              message: message,
              pending: pending,
              actionLabel: action ? 'Undo' : null,
              onAction: action ? onAction ?? () {} : null,
            ),
            child: const Text('Show'),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('ink tokens and flat shape', (tester) async {
    await show(tester);
    final context = tester.element(find.byType(SnackBar));
    final theme = PaymentTheme.of(context);
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.backgroundColor, theme.textPrimary);
    expect(bar.elevation, 0);
    expect(bar.persist, true);
    expect(
      bar.shape,
      RoundedRectangleBorder(borderRadius: theme.controlBorderRadius),
    );
    expect(
      DefaultTextStyle.of(tester.element(find.text('Copied'))).style.color,
      theme.surface,
    );
  });
  for (final (message, seconds, action) in [
    ('Copied', 4, false),
    ('Copied', 6, true),
    (List.filled(20, 'word').join(' '), 7, false),
    (List.filled(60, 'word').join(' '), 10, false),
  ]) {
    testWidgets('reading timeout $seconds action=$action', (tester) async {
      await show(tester, message: message, action: action);
      await tester.pump(Duration(milliseconds: seconds * 1000 - 400));
      expect(find.text(message), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(message), findsNothing);
    });
  }
  testWidgets('pending updates the same element and then times out', (
    tester,
  ) async {
    await show(tester, message: 'Refreshing balance', pending: true);
    final element = tester.element(find.byType(SnackBar));
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(PaymentSpinner), findsOneWidget);
    controller.update('Balance updated', tone: StatusTone.success);
    await tester.pump();
    expect(tester.element(find.byType(SnackBar)), same(element));
    expect(find.byIcon(PaymentIcons.success), findsOneWidget);
    expect(find.byType(PaymentSpinner), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('action runs once and closes', (tester) async {
    var calls = 0;
    await show(tester, action: true, onAction: () => calls++);
    expect(
      tester.getSize(find.widgetWithText(TextButton, 'Undo')).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(SnackBar), findsNothing);
    controller.dismiss();
    controller.update('Ignored');
    await controller.closed;
  });
  testWidgets('teardown cancels timer', (tester) async {
    await show(tester);
    await tester.pumpWidget(const SizedBox());
    controller.update('Ignored');
    controller.dismiss();
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });
}
