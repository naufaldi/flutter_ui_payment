import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('large text chips wrap at phone width', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 320,
          child: PaymentChipList(
            children: [
              PaymentChip(
                label: 'Method',
                values: const ['Transfer', 'QRIS', 'Card'],
                onDropdown: () {},
              ),
              PaymentChip(label: 'Date', value: '1–31 Oct', onClose: () {}),
            ],
          ),
        ),
        2,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('remove target is separate and at least 48 dp', (tester) async {
    var removed = 0, opened = 0;
    await tester.pumpWidget(
      host(
        PaymentChip(
          label: 'Date',
          value: '1–31 Oct',
          onClose: () => removed++,
          onDropdown: () => opened++,
        ),
        1,
      ),
    );
    expect(find.bySemanticsLabel('Date: 1–31 Oct'), findsOneWidget);
    final close = find.byType(PaymentIconButton);
    expect(tester.getSize(close).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('Remove Date'));
    await tester.pump();
    expect(removed, 1);
    expect(opened, 0);
  });
  testWidgets('promo uses removable chip and applied announcement', (
    tester,
  ) async {
    var removed = false;
    await tester.pumpWidget(
      host(
        PromoCodeInput(
          status: PromoCodeStatus.applied,
          appliedCode: 'HEMAT10',
          onRemove: () => removed = true,
          onApply: (_) async {},
        ),
        1,
      ),
    );
    expect(find.text('HEMAT10'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.liveRegion == true &&
            w.properties.label == 'HEMAT10 applied',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Remove Promo code'));
    expect(removed, isTrue);
  });
}
