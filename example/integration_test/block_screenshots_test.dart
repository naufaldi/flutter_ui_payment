import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui_example/checkout_block_demo.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Native docs proof for the standalone block, using the existing in-app
/// capture path. The deterministic adapter sends no network/platform effects.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture checkout block on the Android phone', (tester) async {
    Future<void> start(
      CheckoutDemoScenario scenario, {
      bool dark = false,
    }) async {
      await tester.pumpWidget(
        CheckoutBlockDemo(
          key: UniqueKey(),
          host: CheckoutDemoHost(scenario: scenario, delay: Duration.zero),
          initialDark: dark,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> press(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    for (final dark in [false, true]) {
      final suffix = dark ? '_dark' : '';
      await start(CheckoutDemoScenario.lostResponse, dark: dark);
      await capture(binding, tester, 'android_block_checkout_review$suffix');
      await tester.tap(find.textContaining(RegExp(r'^Bayar Rp')));
      await tester.pumpAndSettle();
      await capture(binding, tester, 'android_block_checkout_unknown$suffix');
      await press('Cek status');
      await capture(binding, tester, 'android_block_checkout_receipt$suffix');
      expect(tester.takeException(), isNull);
    }
    await start(CheckoutDemoScenario.pendingOffline);
    await tester.tap(find.textContaining(RegExp(r'^Bayar Rp')));
    await tester.pumpAndSettle();
    await press('Cek status');
    await capture(binding, tester, 'android_block_checkout_offline');
    expect(tester.takeException(), isNull);
  });
}
