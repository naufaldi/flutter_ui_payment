import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Native visual proof: key screens in light, dark and 200% text.
/// Run with `flutter drive` and test_driver/integration_driver.dart.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const looks = {
    'light': DemoSettings(),
    'dark': DemoSettings(themeMode: ThemeMode.dark),
    'light_200': DemoSettings(textScale: 2),
  };

  testWidgets('capture key screens', (tester) async {
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final app = await launch(tester);
    final platform = Platform.isIOS ? 'ios' : 'android';

    Future<void> shot(String screen, String look) async {
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await binding.takeScreenshot('${platform}_${screen}_$look');
    }

    for (final MapEntry(key: look, value: settings) in looks.entries) {
      app.updateSettings(settings);
      await tester.pump();

      var c = await runScenario(tester, app, 'K07', variant: 2);
      await shot('kyc_review', look);

      c = await runScenario(tester, app, 'H02');
      await pumpUntil(tester, () => c.quote != null && !c.quoting);
      await shot('checkout', look);

      // A changed total: the confirmation with the old → new notice and the
      // consent checkbox.
      c = await runScenario(tester, app, 'P02', variant: 2);
      await pumpUntil(tester, () => c.quote != null && !c.quoting);
      c.reviewOrder();
      await c.confirm();
      await pumpUntil(tester, () => c.quote?.revision == 2 && !c.confirming);
      await shot('requote', look);

      c = await runScenario(tester, app, 'P06');
      await pumpUntil(tester, () => c.quote != null && !c.quoting);
      c.reviewOrder();
      await c.confirm();
      await pumpUntil(tester, () => c.step == FlowStep.authorize);
      await shot('authorize', look);
      await c.authorize();
      await pumpUntil(
        tester,
        () => c.attempt?.submission == SubmissionState.outcomeUnknown,
      );
      await shot('status_unknown', look);

      c = await runScenario(tester, app, 'P07');
      await pumpUntil(tester, () => c.attempt?.status == PaymentStatus.pending);
      await shot('status_pending', look);

      c = await runScenario(tester, app, 'P09');
      await pumpUntil(tester, () => c.attempt?.status == PaymentStatus.pending);
      await shot('status_va_pending', look);

      c = await runScenario(tester, app, 'P15');
      await pumpUntil(
        tester,
        () => c.attempt?.status == PaymentStatus.succeeded,
      );
      await c.paymentAction(PaymentAction.viewReceipt);
      await pumpUntil(tester, () => c.receipt != null);
      await shot('receipt', look);
    }
  });
}
