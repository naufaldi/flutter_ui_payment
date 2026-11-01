import 'package:flutter/services.dart';
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
  testWidgets('A02 detail modules, attempts and reference copying', (t) async {
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final app = await launch(t);
    final c = await runScenario(t, app, 'A02');
    await pumpUntil(t, () => !c.detailLoading);
    await settle(t);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Attempts'), findsOneWidget);
    expect(c.detailAttempts.length, 2);
    await tapVisible(t, find.byType(PaymentCopyButton));
    await pumpUntilFound(t, find.byIcon(PaymentIcons.copied));
    await drain(t);
  });
  testWidgets('A02 report discard, safe submission and retry', (t) async {
    final app = await launch(t);
    var c = await runScenario(t, app, 'A02');
    await pumpUntil(t, () => !c.detailLoading);
    await settle(t);
    Future<void> open() async {
      final direct = find.byKey(const Key('report-problem'));
      if (direct.evaluate().isNotEmpty) {
        await tapVisible(t, direct);
      } else {
        await tapVisible(t, find.byTooltip('More actions'));
        await tapVisible(t, find.text('Report a problem'));
      }
    }

    Future<void> choose() async {
      await tapVisible(
        t,
        find
            .descendant(
              of: find.byType(PaymentSelect<String>),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tapVisible(t, find.text('Charged twice'));
    }

    final editor = find.descendant(
      of: find.byType(PaymentTextArea),
      matching: find.byType(EditableText),
    );
    await open();
    expect(
      t.widget<PaymentButton>(find.byKey(const Key('send-report'))).onPressed,
      isNull,
    );
    await t.enterText(editor, 'test note');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(t);
    await tapVisible(t, find.byKey(const Key('report-cancel')));
    expect(find.text('Discard this report?'), findsOneWidget);
    await tapVisible(t, find.text('Discard'));
    await settle(t);
    expect(find.byType(PaymentFocusView), findsNothing);
    await open();
    await choose();
    await t.enterText(editor, 'test note');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(t);
    await tapVisible(t, find.byKey(const Key('send-report')));
    await pumpUntilFound(t, find.textContaining('Report sent'));
    await settle(t);
    expect(find.byType(PaymentFocusView), findsNothing);
    expect(
      c.host.log.value.any(
        (e) => e.message == 'Problem reported (chargedTwice, 9 chars)',
      ),
      isTrue,
    );
    expect(
      c.host.log.value.any((e) => e.message.contains('test note')),
      isFalse,
    );
    c = await runScenario(t, app, 'A02', variant: 1);
    await pumpUntil(t, () => !c.detailLoading);
    await settle(t);
    await open();
    await choose();
    await tapVisible(t, find.byKey(const Key('send-report')));
    await settle(t);
    expect(find.byType(PaymentBanner), findsOneWidget);
    expect(find.byType(PaymentFocusView), findsOneWidget);
    await tapVisible(t, find.byKey(const Key('report-cancel')));
    await tapVisible(t, find.text('Discard'));
    await settle(t);
    await drain(t);
  });
  testWidgets('A03 page selection, amount sort and search', (t) async {
    surface(t, const Size(393, 852));
    final app = await launch(t);
    final c = await runScenario(t, app, 'A03');
    await pumpUntil(t, () => c.settlements.isNotEmpty);
    await settle(t);
    await tapVisible(t, find.text('Select all on this page'));
    expect(c.selectedSettlements.length, 10);
    expect(find.text('Download selected (10)'), findsOneWidget);
    await tapVisible(t, find.text('Sort: Date, newest first'));
    await tapVisible(
      t,
      find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text('Amount, highest first'),
      ),
    );
    // Narrow ID titles show non-breaking hyphens (U+2011).
    Finder id(String value) => find.text(value.replaceAll('-', '\u2011'));
    expect(id('STL-DEMO-0023'), findsOneWidget);
    final search = find.descendant(
      of: find.byType(PaymentTextField),
      matching: find.byType(EditableText),
    );
    await t.enterText(search, '0023');
    await settle(t);
    expect(id('STL-DEMO-0023'), findsOneWidget);
    expect(id('STL-DEMO-0022'), findsNothing);
    await drain(t);
  });
  testWidgets('A04 fees and help tooltip', (t) async {
    final app = await launch(t);
    await runScenario(t, app, 'A04');
    expect(find.byType(PaymentTable), findsOneWidget);
    expect(find.text('Virtual account'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    // D49: the info button opens its one-line hint on tap.
    const hint = 'Set by Ruang Bayar for each payment method.';
    expect(find.text(hint), findsNothing);
    await tapVisible(t, find.byKey(const Key('fees-info')));
    expect(find.text(hint), findsOneWidget);
    await t.tap(find.byKey(const Key('fees-info')));
    await t.pump();
    expect(find.text(hint), findsNothing);
    await drain(t);
  });
  testWidgets('A05 grouped settings saves, clears status on edit and retries', (
    t,
  ) async {
    final app = await launch(t);
    var c = await runScenario(t, app, 'A05');
    await tapVisible(t, find.text('Promotions'));
    expect(c.accountSettings.promotions, isTrue);
    await tapVisible(t, find.text('Save'));
    expect(find.byType(PaymentSpinner), findsWidgets);
    await pumpUntil(t, () => c.settingsStatus != null);
    await settle(t);
    expect(find.text('Saved'), findsOneWidget);
    await tapVisible(t, find.text('Promotions'));
    expect(c.settingsStatus, isNull);
    c = await runScenario(t, app, 'A05', variant: 1);
    await tapVisible(t, find.text('Save'));
    await pumpUntil(t, () => c.settingsStatus != null);
    await settle(t);
    expect(find.text("Couldn't save. Try again."), findsOneWidget);
    await tapVisible(t, find.text('Save'));
    await pumpUntil(t, () => c.settingsStatus == 'saved');
    await drain(t);
  });

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
