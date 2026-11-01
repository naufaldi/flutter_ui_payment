import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  const facts = [
    PaymentPropertyListItem(label: 'Method', valueText: 'BCA virtual account'),
    PaymentPropertyListItem(label: 'Date', valueText: '1 Oct 2026'),
  ];
  test('a fact has exactly one value', () {
    expect(
      () => PaymentPropertyListItem(
        label: 'Bad',
        valueText: 'both',
        value: const Text('both'),
      ),
      throwsAssertionError,
    );
  });
  testWidgets('vertical facts and heading semantics', (t) async {
    final semantics = t.ensureSemantics();

    await t.pumpWidget(
      contentHost(const PaymentPropertyList(title: 'Details', items: facts)),
    );
    expect(find.byType(InfoRow), findsNWidgets(2));
    expect(
      find.bySemanticsLabel(RegExp('Method.*BCA', dotAll: true)),
      findsOneWidget,
    );
    expect(
      t.getSemantics(find.text('Details')).flagsCollection.isHeader,
      isTrue,
    );
    semantics.dispose();
  });
  testWidgets('horizontal facts collapse for narrow and large text', (t) async {
    await setSurface(t, const Size(800, 1000));
    await t.pumpWidget(
      contentHost(
        const PaymentPropertyList(orientation: Axis.horizontal, items: facts),
      ),
    );
    expect(
      t.getTopLeft(find.text('Method')).dy,
      t.getTopLeft(find.text('Date')).dy,
    );
    for (final dark in [false, true]) {
      await t.pumpWidget(
        contentHost(
          const PaymentPropertyList(orientation: Axis.horizontal, items: facts),
          scale: 2,
          dark: dark,
        ),
      );
      expect(find.byType(InfoRow), findsNWidgets(2));
      expect(t.takeException(), isNull);
    }
    await setSurface(t, const Size(320, 1000));
    await t.pumpWidget(
      contentHost(
        const PaymentPropertyList(orientation: Axis.horizontal, items: facts),
      ),
    );
    expect(find.byType(InfoRow), findsNWidgets(2));
  });
  testWidgets('a reference row is monospace, unfilled and copies its value', (
    t,
  ) async {
    await setSurface(t, const Size(393, 844));
    final copied = <String>[];
    await t.pumpWidget(
      contentHost(
        PaymentPropertyList(
          items: [
            PaymentPropertyListItem(
              label: 'Reference',
              valueText: 'TRX-DEMO-42',
              reference: true,
              trailing: PaymentCopyButton(
                value: 'TRX-DEMO-42',
                onCopy: (v) async {
                  copied.add(v);
                  return true;
                },
              ),
            ),
          ],
        ),
      ),
    );
    final context = t.element(find.text('TRX-DEMO-42'));
    final theme = PaymentTheme.of(context);
    final style = t.widget<Text>(find.text('TRX-DEMO-42')).style!;
    expect(style.fontFamily, theme.referenceFontFamily);
    expect(find.byType(PaymentCode), findsNothing);
    expect(
      find.descendant(
        of: find.byType(InfoRow),
        matching: find.byWidgetPredicate(
          (w) => w is DecoratedBox || w is ColoredBox,
        ),
      ),
      findsNothing,
    );
    // The copy glyph ends on the row's value edge; the 48 dp target stays
    // inside the row.
    final row = t.getRect(find.byType(InfoRow));
    final glyph = t.getRect(find.byIcon(PaymentIcons.copy));
    expect(glyph.right, row.right);
    final target = t.getRect(find.byType(IconButton));
    expect(target.size, const Size(48, 48));
    expect(row.contains(target.topLeft) && target.right <= row.right, isTrue);
    // The value ends where the button starts, and the button centres on the
    // first line.
    expect(
      t.getCenter(find.byIcon(PaymentIcons.copy)).dy,
      closeTo(t.getCenter(find.text('Reference')).dy, 0.5),
    );
    await t.tap(find.byType(IconButton));
    await t.pump();
    expect(copied, ['TRX-DEMO-42']);
  });
  testWidgets('detail values copy references from the value edge', (t) async {
    await setSurface(t, const Size(393, 844));
    final copied = <String>[];
    await t.pumpWidget(
      contentHost(
        PaymentDetailPagePropertyList(
          title: 'Merchant',
          pending: false,
          items: [
            PaymentDetailProperty(
              label: 'Order',
              values: [
                PaymentDetailValue(
                  'DEMO-42',
                  reference: true,
                  onCopy: (v) async {
                    copied.add(v);
                    return true;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final theme = PaymentTheme.of(t.element(find.text('DEMO-42')));
    expect(
      t.widget<Text>(find.text('DEMO-42')).style!.fontFamily,
      theme.referenceFontFamily,
    );
    expect(
      t.getRect(find.byIcon(PaymentIcons.copy)).right,
      t.getRect(find.byType(InfoRow)).right,
    );
    await t.tap(find.byType(IconButton));
    await t.pump();
    expect(copied, ['DEMO-42']);
  });
}
