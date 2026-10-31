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
}
