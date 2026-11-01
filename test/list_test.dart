import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets(
    'list dispatches ids, overrides handlers, and leaves values read-only',
    (tester) async {
      final ids = <String>[];
      var calls = 0;
      await tester.pumpWidget(
        host(
          PaymentList(
            onAction: ids.add,
            children: [
              const PaymentListItem(id: 'history', title: 'History'),
              PaymentListItem(
                id: 'pin',
                title: 'PIN',
                onPressed: () => calls++,
              ),
              const PaymentListItem(title: 'Balance', value: Text('Rp250.000')),
              const PaymentListItem(
                title: 'Disabled',
                disabledReason: 'Managed by your bank',
              ),
            ],
          ),
          1,
        ),
      );
      await tester.tap(find.text('History'));
      await tester.tap(find.text('PIN'));
      await tester.tap(find.text('Balance'));
      expect(ids, ['history']);
      expect(calls, 1);
      final semantics = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(find.byType(PaymentListItem).at(2))
            .flagsCollection
            .isButton,
        isFalse,
      );
      final disabled = tester.getSemantics(find.byType(PaymentListItem).at(3));
      expect(disabled.flagsCollection.isButton, isTrue);
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
      expect(disabled.label, contains('Managed by your bank'));
      semantics.dispose();
    },
  );
  testWidgets('RTL uses one directional forward glyph', (tester) async {
    await tester.pumpWidget(
      host(
        Directionality(
          textDirection: TextDirection.rtl,
          child: PaymentListItem(title: 'History', onPressed: () {}),
        ),
        1,
      ),
    );
    expect(find.byIcon(PaymentIcons.forward), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
  });
  testWidgets('large targets and keyboard activation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        PaymentListItem(
          title: 'Bank',
          size: PaymentListItemSize.large,
          onPressed: () => calls++,
        ),
        1,
      ),
    );
    expect(
      tester.getSize(find.byType(PaymentListItem)).height,
      greaterThanOrEqualTo(64),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 1);
  });
  testWidgets('value and trailing cannot be combined', (tester) async {
    await tester.pumpWidget(
      host(
        const PaymentListItem(
          title: 'Balance',
          value: Text('5'),
          trailing: Text('Change'),
        ),
        1,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
  testWidgets('large text keeps the amount at label size under the title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        const PaymentList(
          children: [
            PaymentListItem(
              title: 'Groceries at the corner shop',
              secondaryTitle: 'Paid 2 days ago',
              value: AmountText(Money(250000, 'IDR')),
            ),
          ],
        ),
        2,
      ),
    );
    final title = tester.getRect(find.text('Groceries at the corner shop'));
    final amount = tester.getRect(find.byType(AmountText));
    expect(tester.takeException(), isNull);
    expect(amount.height, greaterThanOrEqualTo(40));
    expect(amount.top, greaterThanOrEqualTo(title.bottom));
  });
  testWidgets('a 48 dp trailing control keeps its size beside a title', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PaymentListItem(
          title: 'Card ending 4242',
          trailing: PaymentButton(
            label: 'Change',
            variant: PaymentButtonVariant.quiet,
            size: PaymentSize.small,
            width: PaymentWidth.hug,
            onPressed: () {},
          ),
        ),
        1,
      ),
    );
    final button = tester.getRect(find.byType(PaymentButton));
    final title = tester.getRect(find.text('Card ending 4242'));
    expect(button.height, greaterThanOrEqualTo(48));
    expect(button.center.dy, moreOrLessEquals(title.center.dy, epsilon: 0.5));
  });
}
