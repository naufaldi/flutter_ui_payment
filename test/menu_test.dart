import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void main() {
  testWidgets('groups separate destructive actions and dispatch ids', (
    tester,
  ) async {
    final ids = <String>[];
    await tester.pumpWidget(
      host(
        PaymentMenu(
          onAction: ids.add,
          entries: const [
            PaymentMenuGroup(
              title: 'Receipt',
              items: [
                PaymentMenuItem(label: 'Download', id: 'download'),
                PaymentMenuItem(
                  label: 'Unavailable',
                  id: 'disabled',
                  disabled: true,
                ),
              ],
            ),
            PaymentMenuGroup(
              items: [
                PaymentMenuItem(
                  label: 'Cancel payment',
                  id: 'cancel',
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentDivider), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('Receipt')).flagsCollection.isHeader,
      isTrue,
    );
    semantics.dispose();
    final items = tester
        .widgetList<MenuItemButton>(find.byType(MenuItemButton))
        .toList();
    expect(items[1].onPressed, isNull);
    for (final e in find.byType(MenuItemButton).evaluate()) {
      expect(
        tester.getSize(find.byWidget(e.widget)).height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(ids, ['download']);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Download'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Download'), findsNothing);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).focusNode!.hasFocus,
      isTrue,
    );
  });
  testWidgets('item callback wins and disabled wins over callback', (
    tester,
  ) async {
    var calls = 0;
    final ids = <String>[];
    await tester.pumpWidget(
      host(
        PaymentMenu(
          onAction: ids.add,
          entries: [
            PaymentMenuItem(label: 'Own', id: 'own', onSelected: () => calls++),
            PaymentMenuItem(
              label: 'Disabled',
              disabled: true,
              onSelected: () => calls++,
            ),
          ],
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<MenuItemButton>(find.byType(MenuItemButton))
          .last
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Own'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(ids, isEmpty);
  });
}
