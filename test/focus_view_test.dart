import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  Future<void> open(
    WidgetTester t, {
    bool confirm = false,
    PaymentFocusViewSize size = PaymentFocusViewSize.small,
  }) async {
    await t.pumpWidget(
      contentHost(
        Builder(
          builder: (context) => PaymentButton(
            label: 'Open',
            onPressed: () {
              showPaymentFocusView<void>(
                context,
                size: size,
                builder: (_) => PaymentFocusView(
                  title: 'Report a problem',
                  confirmClose: confirm
                      ? const PaymentConfirmClose(
                          title: 'Discard report?',
                          message: 'Your changes will be lost.',
                          exitLabel: 'Discard',
                        )
                      : null,
                  primaryAction: PaymentButton(label: 'Send', onPressed: () {}),
                  child: const Text('Details'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  testWidgets('phone sheet closes without a drag handle', (t) async {
    await setSurface(t, const Size(393, 844));
    await open(t);
    expect(find.byType(PaymentFocusView), findsOneWidget);
    expect(t.widget<BottomSheet>(find.byType(BottomSheet)).enableDrag, false);
    await t.tap(find.byTooltip('Close panel'));
    await t.pumpAndSettle();
    expect(find.byType(PaymentFocusView), findsNothing);
  });
  testWidgets('wide small and large panel sizes', (t) async {
    await setSurface(t, const Size(1024, 900));
    for (final size in PaymentFocusViewSize.values) {
      await open(t, size: size);
      expect(
        t.getSize(find.byType(PaymentFocusView)).width,
        size == PaymentFocusViewSize.small ? 420 : 720,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(PaymentFocusView), findsNothing);
    }
  });
  testWidgets('close, scrim, Escape and back ask before discarding', (t) async {
    await setSurface(t, const Size(393, 844));
    for (final way in ['close', 'scrim', 'escape', 'back']) {
      await open(t, confirm: true);
      switch (way) {
        case 'close':
          await t.tap(find.byTooltip('Close panel'));
        case 'scrim':
          await t.tapAt(const Offset(4, 4));
        case 'escape':
          await t.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'back':
          await t.binding.handlePopRoute();
      }
      await t.pumpAndSettle();
      expect(find.text('Discard report?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.byType(PaymentFocusView), findsOneWidget);
      await t.tap(find.byTooltip('Close panel'));
      await t.pumpAndSettle();
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      expect(find.byType(PaymentFocusView), findsNothing);
    }
  });
}
