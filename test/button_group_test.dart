import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  testWidgets('auto retains first, exposes overflow and isolates danger', (
    t,
  ) async {
    await setSurface(t, const Size(320, 1000));
    var calls = 0;
    await t.pumpWidget(
      contentHost(
        SizedBox(
          width: 220,
          child: PaymentButtonGroup(
            children: [
              PaymentButton(
                label: 'Share',
                variant: PaymentButtonVariant.secondary,
                onPressed: () {},
              ),
              PaymentButton(
                label: 'Download',
                variant: PaymentButtonVariant.secondary,
                onPressed: () {
                  calls++;
                },
              ),
              PaymentButton(
                label: 'Delete',
                variant: PaymentButtonVariant.destructive,
                onPressed: () {
                  calls++;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byTooltip('More actions'), findsOneWidget);
    await t.tap(find.byTooltip('More actions'));
    await t.pumpAndSettle();
    final menu = find.descendant(
      of: find.byType(MenuItemButton),
      matching: find.text('Download'),
    );
    expect(menu, findsOneWidget);
    await t.tap(menu);
    await t.pumpAndSettle();
    expect(calls, 1);
    expect(t.takeException(), isNull);
  });
  testWidgets('none stacks emphasized action above cancel', (t) async {
    await t.pumpWidget(
      contentHost(
        SizedBox(
          width: 220,
          child: PaymentButtonGroup(
            collapse: PaymentButtonGroupCollapse.none,
            children: [
              PaymentButton(
                label: 'Cancel',
                variant: PaymentButtonVariant.quiet,
                onPressed: () {},
              ),
              PaymentButton(
                label: 'Remove card',
                variant: PaymentButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      t.getTopLeft(find.text('Remove card')).dy,
      lessThan(t.getTopLeft(find.text('Cancel')).dy),
    );
    // Stacked buttons fill the group's width, so no edge is ragged (#65).
    for (final label in ['Remove card', 'Cancel']) {
      final rect = t.getRect(find.widgetWithText(PaymentButton, label));
      expect(rect.width, 220);
    }
    expect(t.takeException(), isNull);
  });
  testWidgets('none keeps one row of hug buttons when they fit', (t) async {
    await t.pumpWidget(
      contentHost(
        SizedBox(
          width: 360,
          child: PaymentButtonGroup(
            collapse: PaymentButtonGroupCollapse.none,
            children: [
              PaymentButton(
                label: 'Cancel',
                variant: PaymentButtonVariant.quiet,
                onPressed: () {},
              ),
              PaymentButton(label: 'Save', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    final cancel = t.getRect(find.widgetWithText(PaymentButton, 'Cancel'));
    final save = t.getRect(find.widgetWithText(PaymentButton, 'Save'));
    expect(cancel.top, save.top);
    expect(cancel.right, lessThan(save.left));
    expect(save.width, lessThan(360));
    expect(t.takeException(), isNull);
  });
  testWidgets('vertical fills and keeps host order', (t) async {
    await t.pumpWidget(
      contentHost(
        PaymentButtonGroup(
          direction: Axis.vertical,
          children: [
            PaymentButton(label: 'Continue', onPressed: () {}),
            PaymentButton(
              label: 'Help',
              variant: PaymentButtonVariant.quiet,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    expect(
      t.getTopLeft(find.text('Continue')).dy,
      lessThan(t.getTopLeft(find.text('Help')).dy),
    );
    expect(t.takeException(), isNull);
  });
  testWidgets('overflow opens full-width sheet rows on a phone', (t) async {
    await setSurface(t, const Size(320, 1000));
    await t.pumpWidget(
      contentHost(
        PaymentButtonGroup(
          children: [
            PaymentButton(
              label: 'Share',
              variant: PaymentButtonVariant.secondary,
              onPressed: () {},
            ),
            PaymentButton(
              label: 'Download statement for October 2026',
              variant: PaymentButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
        scale: 2,
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('More actions'));
    await t.pumpAndSettle();
    final label = find.descendant(
      of: find.byType(MenuItemButton),
      matching: find.text('Download statement for October 2026'),
    );
    // D55: on a phone the overflow is an action sheet with full-width rows.
    final row = t.getRect(
      find.ancestor(of: label, matching: find.byType(MenuItemButton)),
    );
    expect(row.width, 320);
    expect(row.height, greaterThanOrEqualTo(48));
    expect(t.takeException(), isNull);
  });
  testWidgets('only one primary allowed', (t) async {
    await t.pumpWidget(
      contentHost(
        PaymentButtonGroup(
          children: [
            PaymentButton(label: 'One', onPressed: () {}),
            PaymentButton(label: 'Two', onPressed: () {}),
          ],
        ),
      ),
    );
    expect(t.takeException(), isAssertionError);
  });
}
