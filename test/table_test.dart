import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

void main() {
  testWidgets('cell numeric flag selects tabular column figures', (t) async {
    await setSurface(t, const Size(800, 1000));
    await t.pumpWidget(
      contentHost(
        const PaymentTable(
          head: [
            PaymentTableHeaderCell('Method'),
            PaymentTableHeaderCell('Fee'),
          ],
          rows: [
            PaymentTableRow([
              PaymentTableCell(Text('QRIS')),
              PaymentTableCell(Text('2500'), numeric: true),
            ]),
          ],
        ),
      ),
    );
    final style = DefaultTextStyle.of(t.element(find.text('2500'))).style;
    expect(style.fontFeatures, isNotEmpty);
  });

  const table = PaymentTable(
    head: [
      PaymentTableHeaderCell('Method', rowHeader: true),
      PaymentTableHeaderCell('Fee', numeric: true),
      PaymentTableHeaderCell('Arrives'),
    ],
    rows: [
      PaymentTableRow([
        PaymentTableCell(Text('Virtual account')),
        PaymentTableCell(Text('Rp2.500')),
        PaymentTableCell(Text('Within 10 min')),
      ]),
      PaymentTableRow([
        PaymentTableCell(Text('QRIS')),
        PaymentTableCell(Text('Rp0')),
        PaymentTableCell(Text('Instant')),
      ]),
    ],
    footer: PaymentTableRow([
      PaymentTableCell(Text('Total')),
      PaymentTableCell(Text('Rp2.500')),
      PaymentTableCell(Text('')),
    ]),
  );
  testWidgets('wide table labels cells and aligns numbers', (t) async {
    await setSurface(t, const Size(800, 1000));
    final semantics = t.ensureSemantics();

    await t.pumpWidget(contentHost(table));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Fee: ')), findsWidgets);
    expect(
      t.getBottomRight(find.text('Rp2.500').first).dx,
      t.getBottomRight(find.text('Rp0')).dx,
    );
    expect(find.byType(Table), findsNWidgets(2));
    expect(t.takeException(), isNull);
    semantics.dispose();
  });
  testWidgets('narrow and large text become list rows with total', (t) async {
    for (final size in [const Size(320, 1000), const Size(800, 1000)]) {
      await setSurface(t, size);
      for (final dark in [false, true]) {
        await t.pumpWidget(
          contentHost(table, scale: size.width == 800 ? 2 : 1, dark: dark),
        );
        expect(find.byType(Table), findsNothing);
        expect(find.byType(InfoRow), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(t.takeException(), isNull);
      }
    }
  });
  testWidgets('table skeleton adapts and speaks loading', (t) async {
    for (final width in [320.0, 800.0]) {
      await setSurface(t, Size(width, 1000));
      await t.pumpWidget(contentHost(const LoadingSkeleton.table(rows: 3)));
      expect(t.takeException(), isNull);
    }
  });
}
