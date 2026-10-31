import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import '../integration_test/support.dart';

Future<void> drain(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 2));
}

void surface(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('H04 signs in without credential fields', (t) async {
    final app = await launch(t);
    final c = await runScenario(t, app, 'H04');
    expect(c.step, FlowStep.signIn);
    expect(
      find.descendant(
        of: find.byType(PaymentSignInView),
        matching: find.byType(EditableText),
      ),
      findsNothing,
    );
    await tapVisible(t, find.byKey(const Key('sign-in')));
    await pumpUntil(t, () => c.step == FlowStep.overview);
    expect(c.signedIn, isTrue);
    await drain(t);
  });
  testWidgets('H04 cancellation can retry', (t) async {
    final app = await launch(t);
    final c = await runScenario(t, app, 'H04', variant: 1);
    await tapVisible(t, find.byKey(const Key('sign-in')));
    await pumpUntil(t, () => c.signInError);
    expect(find.text('Sign-in was canceled. Try again.'), findsOneWidget);
    await tapVisible(t, find.byKey(const Key('sign-in')));
    await pumpUntil(t, () => c.step == FlowStep.overview);
    await drain(t);
  });
  testWidgets('KYC onboarding groups details and searches province', (t) async {
    final app = await launch(t);
    final c = await runScenario(t, app, 'H01');
    await tapVisible(t, find.byKey(const Key('buy')));
    await tapVisible(t, find.byType(PaymentCheckbox));
    await tapVisible(t, find.text('Continue'));
    expect(find.byType(PaymentOnboardingView), findsOneWidget);
    expect(find.text('Step 1 of 3: Your details'), findsOneWidget);
    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('Work and address'), findsOneWidget);
    await fillIdentity(t);
    await tapVisible(t, find.text('Continue'));
    await pumpUntil(t, () => c.step == FlowStep.kycDocuments);
    expect(c.identity['province'], 'jawa-barat');
    await drain(t);
  });
  testWidgets('A01 filters, empty state and retry', (t) async {
    final app = await launch(t);
    var c = await runScenario(t, app, 'A01');
    await pumpUntil(t, () => !c.historyLoading);
    await settle(t);
    expect(find.text('Spending, this month vs last'), findsOneWidget);
    await tapVisible(t, find.text('Refunds').last);
    expect(c.historyFilter, TransactionFilter.refunds);
    expect(find.byType(PaymentChip), findsOneWidget);
    final close = find.descendant(
      of: find.byType(PaymentChip),
      matching: find.byType(PaymentIconButton),
    );
    await tapVisible(t, close);
    expect(c.historyFilter, TransactionFilter.all);
    c.setHistoryQuery('Toko');
    c.setHistoryFilter(TransactionFilter.succeeded);
    await settle(t);
    await tapVisible(t, find.text('Clear all'));
    expect(find.byType(PaymentChip), findsNothing);
    c = await runScenario(t, app, 'A01', variant: 1);
    await pumpUntil(t, () => !c.historyLoading);
    await settle(t);
    expect(c.history, isEmpty);
    expect(find.byType(StateMessage), findsWidgets);
    c = await runScenario(t, app, 'A01', variant: 2);
    await pumpUntil(t, () => !c.historyLoading);
    await settle(t);
    expect(find.text("Transactions didn't load"), findsOneWidget);
    await tapVisible(t, find.text('Retry'));
    await pumpUntil(t, () => !c.historyLoading);
    expect(c.history, isNotEmpty);
    await drain(t);
  });
  testWidgets('wide checkout adds order context only when it fits', (t) async {
    surface(t, const Size(1280, 900));
    final app = await launch(t);
    await runScenario(t, app, 'H02');
    expect(find.byType(PaymentContextView), findsOneWidget);
    t.view.physicalSize = const Size(393, 852);
    await settle(t);
    expect(find.byType(PaymentContextView), findsNothing);
    await drain(t);
  });
  testWidgets('wide onboarding shows tasks without phone accordion', (t) async {
    surface(t, const Size(1280, 900));
    final app = await launch(t);
    await runScenario(t, app, 'H01');
    await tapVisible(t, find.byKey(const Key('buy')));
    await tapVisible(t, find.byType(PaymentCheckbox));
    await tapVisible(t, find.text('Continue'));
    expect(find.byType(PaymentTaskList), findsOneWidget);
    expect(find.text('All steps'), findsNothing);
    await drain(t);
  });
}
