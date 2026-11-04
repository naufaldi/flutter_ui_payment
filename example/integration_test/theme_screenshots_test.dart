import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment_example/merchant_demo.dart';
import 'package:flutter_ui_payment_example/themes.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Native docs proof for the Soft host preset (#151): the Merchant overview
/// block in a host inset panel on the tinted page, light and dark.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture the Soft merchant overview', (tester) async {
    await tester.pumpWidget(const MerchantDemo(brand: DemoBrand.soft));
    await tester.pumpAndSettle();
    await capture(binding, tester, 'android_block_merchant_soft');
    // The demo's own settings switch, as a person would turn on dark mode.
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ringkasan'));
    await tester.pumpAndSettle();
    await capture(binding, tester, 'android_block_merchant_soft_dark');
    expect(tester.takeException(), isNull);
  });
}
