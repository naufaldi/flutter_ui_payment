import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/manual_transfer_demo.dart';

import 'support/small_screen.dart';

const vaNumber = '8808 1234 5678 9012';

PaymentAttempt attemptOf(WidgetTester tester) =>
    tester.widget<PaymentStatusView>(find.byType(PaymentStatusView)).attempt;

Future<void> pumpDemo(
  WidgetTester tester,
  ManualTransferScenario scenario, {
  bool dark = false,
  int minutesAfterIssue = 18,
}) async {
  final now = manualTransferIssuedAt.add(Duration(minutes: minutesAfterIssue));
  await tester.pumpWidget(
    ManualTransferDemo(
      initialScenario: scenario,
      initialDark: dark,
      delay: Duration.zero,
      clock: () => now,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> checkStatus(WidgetTester tester) async {
  final check = find.text('Cek status');
  await tester.ensureVisible(check);
  await tester.tap(check);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the payer reads the exact account and amount, then checking '
      'reports success for the same attempt', (tester) async {
    await pumpDemo(tester, ManualTransferScenario.open);
    expect(find.text(vaNumber), findsOneWidget);
    expect(find.textContaining('152.500'), findsWidgets);

    await checkStatus(tester);
    final attempt = attemptOf(tester);
    expect(attempt.attemptId, 'VA-DEMO-217');
    expect(attempt.snapshot!.status, PaymentStatus.succeeded);
    // Paid: the transfer instructions are no longer offered.
    expect(find.text(vaNumber), findsNothing);
  });

  testWidgets('a passed deadline warns but never decides the payment; the '
      'host answer does', (tester) async {
    await pumpDemo(
      tester,
      ManualTransferScenario.elapsed,
      minutesAfterIssue: 75,
    );
    final l10n = PaymentLocalizations('id');
    expect(find.text(l10n.instructionsElapsedTitle), findsOneWidget);
    expect(attemptOf(tester).snapshot!.status, PaymentStatus.pending);

    await checkStatus(tester);
    expect(attemptOf(tester).attemptId, 'VA-DEMO-217');
    expect(attemptOf(tester).snapshot!.status, PaymentStatus.succeeded);
  });

  testWidgets('a lost issuing response hides the account and offers only '
      'Check status, never a second transfer', (tester) async {
    await pumpDemo(tester, ManualTransferScenario.issueUnknown);
    expect(find.text(vaNumber), findsNothing);
    expect(attemptOf(tester).availableActions, {PaymentAction.checkStatus});

    await checkStatus(tester);
    expect(find.text(vaNumber), findsOneWidget);
    expect(attemptOf(tester).attemptId, 'VA-DEMO-217');
  });

  testWidgets('a failed check keeps the last known pending status and the '
      'account on screen', (tester) async {
    await pumpDemo(tester, ManualTransferScenario.checkOffline);
    await checkStatus(tester);
    final attempt = attemptOf(tester);
    expect(attempt.observation, Observation.unavailable);
    expect(attempt.snapshot!.status, PaymentStatus.pending);
    expect(find.text(vaNumber), findsOneWidget);

    await checkStatus(tester);
    expect(attemptOf(tester).snapshot!.status, PaymentStatus.succeeded);
  });

  testWidgets('320dp at 200% text in dark mode keeps Check status reachable', (
    tester,
  ) async {
    useSmallScreenLargeText(tester);
    await pumpDemo(
      tester,
      ManualTransferScenario.elapsed,
      dark: true,
      minutesAfterIssue: 75,
    );
    expect(find.text('Cek status').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
