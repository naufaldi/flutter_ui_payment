import 'content_host.dart' as phase4;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets(
    'code wraps by default, noWrap scrolls with fade only on overflow',
    (t) async {
      await phase4.setSurface(t, const Size(320, 1000));
      final text = 'DEMO-${'0123456789' * 6}';
      await t.pumpWidget(phase4.contentHost(PaymentCode(text)));
      await t.pumpAndSettle();
      final wrapped = t.getSize(find.byType(SelectableText));
      expect(wrapped.height, greaterThan(30));
      expect(t.takeException(), isNull);
      await t.pumpWidget(phase4.contentHost(PaymentCode(text, noWrap: true)));
      await t.pumpAndSettle();
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(
        t
            .widgetList<Scrollable>(find.byType(Scrollable))
            .any((s) => s.axisDirection == AxisDirection.right),
        isTrue,
      );
      await t.pumpWidget(
        phase4.contentHost(const PaymentCode('DEMO-42', noWrap: true)),
      );
      await t.pumpAndSettle();
      expect(find.byType(ShaderMask), findsNothing);
    },
  );

  testWidgets('Box token gap and rich inline emphasis', (tester) async {
    await tester.pumpWidget(
      host(
        const PaymentBox(
          gap: PaymentSpace.group,
          children: [
            SizedBox(key: Key('a'), height: 10),
            SizedBox(key: Key('b'), height: 10),
          ],
        ),
        1,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('b'))).dy -
          tester.getBottomLeft(find.byKey(const Key('a'))).dy,
      16,
    );
    await tester.pumpWidget(
      host(
        const PaymentInline.rich([
          PaymentSpan('Pay '),
          PaymentSpan('today', weight: PaymentFontWeight.bold),
        ]),
        1,
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(
      (text.textSpan! as TextSpan).children!.last.style!.fontWeight,
      FontWeight.w700,
    );
  });
  testWidgets('Icon scaling and semantic label', (tester) async {
    for (final scale in [1.0, 2.0, 3.0]) {
      await tester.pumpWidget(
        host(
          const PaymentIcon(Icons.schedule, semanticLabel: 'Due date'),
          scale,
        ),
      );
      expect(tester.widget<Icon>(find.byType(Icon)).size, scale == 1 ? 20 : 32);
      expect(find.bySemanticsLabel('Due date'), findsOneWidget);
    }
  });
  testWidgets('Code groups speech and delegates copy with confirmation', (
    tester,
  ) async {
    String? copied;
    await tester.pumpWidget(
      host(
        PaymentCode(
          '8808001234567890',
          semanticLabel: 'Virtual account number',
          onCopy: (v) async {
            copied = v;
            return true;
          },
        ),
        1,
      ),
    );
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).semanticsLabel,
      'Virtual account number 8808 0012 3456 7890',
    );
    await tester.tap(find.byTooltip('Copy'));
    await tester.pumpAndSettle();
    expect(copied, '8808001234567890');
    expect(find.byIcon(PaymentIcons.copied), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
  test('Keyboard code cannot copy', () {
    expect(
      () => PaymentCode(
        'Tab',
        kind: PaymentCodeKind.kbd,
        onCopy: (_) async => true,
      ),
      throwsAssertionError,
    );
  });
}
