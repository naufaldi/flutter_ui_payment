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
  testWidgets('tap toggles the hint; outside tap and Escape close it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            PaymentTooltip(message: 'Paid on 29 Oct', child: Text('2d ago')),
            SizedBox(height: 200),
            Text('Elsewhere'),
          ],
        ),
        1,
      ),
    );
    await tester.tap(find.text('2d ago'));
    await tester.pump();
    expect(find.text('Paid on 29 Oct'), findsOneWidget);
    await tester.tap(find.text('2d ago'));
    await tester.pump();
    expect(find.text('Paid on 29 Oct'), findsNothing);
    await tester.tap(find.text('2d ago'));
    await tester.pump();
    await tester.tap(find.text('Elsewhere'));
    await tester.pump();
    expect(find.text('Paid on 29 Oct'), findsNothing);
    await tester.tap(find.text('2d ago'));
    await tester.pump();
    expect(find.text('Paid on 29 Oct'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Paid on 29 Oct'), findsNothing);
  });
  testWidgets('Escape is left alone while no hint shows', (tester) async {
    var escapes = 0;
    await tester.pumpWidget(
      host(
        Focus(
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              escapes++;
            }
            return KeyEventResult.ignored;
          },
          child: const PaymentTooltip(message: 'Hint', child: Text('Term')),
        ),
        1,
      ),
    );
    await tester.tap(find.text('Term'));
    await tester.pump();
    await tester.tap(find.text('Term'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(escapes, 1);
  });
  testWidgets(
    'trigger builder toggles from an icon button and keeps its label',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          PaymentTooltip(
            message: 'Fees are set by your bank',
            trigger: (toggle, focusNode) => PaymentIconButton(
              icon: Icons.info_outline,
              tooltip: 'About fees',
              focusNode: focusNode,
              onPressed: toggle,
            ),
          ),
          1,
        ),
      );
      final button = find.byType(IconButton);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Fees are set by your bank'), findsOneWidget);
      // The button's own Material tooltip stays hidden.
      expect(find.text('About fees'), findsNothing);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Fees are set by your bank'), findsNothing);
      // Long press shows only the kit hint.
      await tester.longPress(button);
      await tester.pump();
      expect(find.text('Fees are set by your bank'), findsOneWidget);
      expect(find.text('About fees'), findsNothing);
      final data = tester.getSemantics(button).getSemanticsData();
      expect(data.label, contains('About fees'));
      expect(data.tooltip, contains('Fees are set by your bank'));
      await tester.pump(const Duration(seconds: 2));
      semantics.dispose();
    },
  );
}
