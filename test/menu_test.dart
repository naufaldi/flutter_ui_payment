import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

void surface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('groups separate destructive actions and dispatch ids', (
    tester,
  ) async {
    surface(tester, const Size(1024, 768));
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
    surface(tester, const Size(1024, 768));
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
  testWidgets('wide items without an icon keep the icon column', (
    tester,
  ) async {
    surface(tester, const Size(1024, 768));
    await tester.pumpWidget(
      host(
        const Align(
          alignment: Alignment.topRight,
          child: PaymentMenu(
            entries: [
              PaymentMenuItem(
                label: 'Download',
                id: 'download',
                icon: Icons.download,
              ),
              PaymentMenuItem(label: 'Export history', id: 'export'),
            ],
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Export history')).dx,
      tester.getTopLeft(find.text('Download')).dx,
    );
    // The panel keeps 16 dp from the window edge.
    final panel = tester.getRect(
      find.ancestor(
        of: find.text('Download'),
        matching: find.byType(MenuItemButton),
      ),
    );
    expect(panel.right, lessThanOrEqualTo(1024 - 16));
    // With room, the box starts under the trigger's start edge.
    await tester.tapAt(const Offset(500, 500));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      host(
        const Padding(
          padding: EdgeInsets.only(left: 24),
          child: Align(
            alignment: Alignment.topLeft,
            child: PaymentMenu(
              entries: [PaymentMenuItem(label: 'Download', id: 'download')],
            ),
          ),
        ),
        1,
      ),
    );
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(
            find.ancestor(
              of: find.text('Download'),
              matching: find.byType(MenuItemButton),
            ),
          )
          .left,
      24,
    );
  });
  testWidgets('compact opens an action sheet and dispatches after close', (
    tester,
  ) async {
    surface(tester, const Size(393, 844));
    final ids = <String>[];
    var dispatchedWhileOpen = false;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => PaymentMenu(
            onAction: (id) {
              // The page route is current again once the sheet has popped.
              dispatchedWhileOpen = !ModalRoute.of(context)!.isCurrent;
              ids.add(id);
            },
            entries: const [
              PaymentMenuItem(
                label: 'Remove card',
                id: 'remove',
                icon: Icons.delete_outline,
                destructive: true,
              ),
              PaymentMenuGroup(
                title: 'Receipt',
                items: [
                  PaymentMenuItem(
                    label: 'Download',
                    id: 'download',
                    icon: Icons.download,
                  ),
                  PaymentMenuItem(label: 'Export history', id: 'export'),
                ],
              ),
            ],
          ),
        ),
        1,
      ),
    );
    final trigger = find.byTooltip('More actions');
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    // Full-width 48 dp rows; the icon-less item keeps the icon column.
    for (final label in ['Download', 'Export history', 'Remove card']) {
      final row = tester.getRect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(MenuItemButton),
        ),
      );
      expect(row.width, 393);
      expect(row.height, greaterThanOrEqualTo(48));
    }
    expect(
      tester.getTopLeft(find.text('Export history')).dx,
      tester.getTopLeft(find.text('Download')).dx,
    );
    // The destructive item moves last, after a divider, above Cancel.
    final remove = tester.getTopLeft(find.text('Remove card')).dy;
    expect(
      remove,
      greaterThan(tester.getTopLeft(find.text('Export history')).dy),
    );
    expect(find.byType(PaymentDivider), findsOneWidget);
    final cancel = find.widgetWithText(PaymentButton, 'Cancel');
    expect(tester.getTopLeft(cancel).dy, greaterThan(remove));
    expect(tester.getSize(cancel).width, 393 - 32);
    // Cancel dispatches nothing and returns focus to the trigger.
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(ids, isEmpty);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).focusNode!.hasFocus,
      isTrue,
    );
    // A selection closes the sheet first, then dispatches once.
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(ids, ['download']);
    expect(dispatchedWhileOpen, isFalse);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).focusNode!.hasFocus,
      isTrue,
    );
    // The scrim dispatches nothing either.
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(ids, ['download']);
  });
}
