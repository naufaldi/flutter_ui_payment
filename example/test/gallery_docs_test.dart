import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/main.dart';
import '../integration_test/support.dart';

void main() {
  testWidgets('English gallery table formats every fee and its total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await launch(tester);
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    app.selectTab(2);
    await settle(tester);
    await tester.tap(find.byTooltip('Open navigation'));
    await settle(tester);
    await tester.tap(find.text('Content'));
    await settle(tester);
    final table = find.byType(PaymentTable);
    await tester.ensureVisible(table);
    await settle(tester);
    for (final amount in ['Rp2,500', 'Rp0', 'Rp4,000', 'Rp1,500', 'Rp8,000']) {
      expect(
        find.descendant(of: table, matching: find.text(amount)),
        findsOneWidget,
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('spacing roles show the resolved theme gaps', (tester) async {
    final app = await launch(tester);
    app.selectTab(2);
    await settle(tester);
    final specimen = find.byKey(
      const ValueKey('specimen:PaymentSpace · variants'),
    );
    await tester.ensureVisible(specimen);
    await settle(tester);
    final theme = PaymentTheme.of(tester.element(specimen));
    for (final role in PaymentSpace.values) {
      final before = tester.getRect(
        find.byKey(ValueKey('space:${role.name}:before')),
      );
      final after = tester.getRect(
        find.byKey(ValueKey('space:${role.name}:after')),
      );
      expect(after.left - before.right, theme.space(role), reason: role.name);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
