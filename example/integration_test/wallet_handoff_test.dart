import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gallery wallet return leaves the original attempt pending', (
    tester,
  ) async {
    final app = await launch(tester);
    app.selectTab(2);
    await settle(tester);
    await openGalleryPage(tester, 'Wallet handoff');

    Future<void> tap(String label) async {
      final target = find.text(label);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await settle(tester);
    }

    PaymentAttempt current() => tester
        .widget<PaymentStatusView>(find.byType(PaymentStatusView))
        .attempt;

    final attemptId = current().attemptId;
    await tap('Open wallet');
    expect(find.text('Waiting for wallet return'), findsOneWidget);
    await tap('Check status');
    await pumpUntil(tester, () => current().observation == Observation.fresh);
    expect(current().snapshot?.revision, 2);
    await tap('Simulate return');
    // An unrelated foreground event is not another wallet return or check.
    for (var i = 0; i < 2; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
    await settle(tester);
    expect(find.text('Back from wallet'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Payment successful'), findsNothing);
    expect(current().attemptId, attemptId);
    expect(current().snapshot?.revision, 2);
    await tap('Check status');
    expect(find.text('Payment successful'), findsOneWidget);
    expect(current().attemptId, attemptId);
  });
}
