import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  for (final (size, dimension) in [
    (PaymentSize.small, 16.0),
    (PaymentSize.medium, 20.0),
    (PaymentSize.large, 32.0),
  ]) {
    testWidgets('spinner $size', (tester) async {
      await tester.pumpWidget(host(PaymentSpinner(size: size), 1));
      expect(
        tester.getSize(find.byType(CircularProgressIndicator)),
        Size.square(dimension),
      );
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .strokeWidth,
        dimension * .12,
      );
    });
  }
  testWidgets('delay reserves space, hides semantics, and cancels on dispose', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      host(const PaymentSpinner(delay: Duration(milliseconds: 300)), 1),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('Loading'), findsNothing);
    expect(tester.getSize(find.byType(PaymentSpinner)), const Size.square(20));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      host(const PaymentSpinner(delay: Duration(milliseconds: 300)), 1),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
  testWidgets('tooltip hover delay, exit and keyboard Escape', (tester) async {
    await tester.pumpWidget(
      host(
        PaymentTooltip(
          message: 'Payment time',
          type: PaymentTooltipType.label,
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.info_outline),
          ),
        ),
        1,
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Payment time'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Payment time'), findsOneWidget);
    await mouse.moveTo(const Offset(700, 500));
    await tester.pump();
    expect(find.text('Payment time'), findsNothing);
    await mouse.removePointer();
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.text('Payment time'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Payment time'), findsNothing);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });
}
