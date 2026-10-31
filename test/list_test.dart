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
}
